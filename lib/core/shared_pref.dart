import 'dart:convert';
import 'dart:developer' as developer;
import 'package:fpdart/fpdart.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
import 'package:myapp/models/user/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefKey<ST, LT> {
  final dynamic Function(Map<String, dynamic> json)? fromJson;
  final String name;
  const PrefKey({this.fromJson, required this.name});

  static const cyId = PrefKey<String, Unit>(name: 'cyId');
  static const lastSync = PrefKey<int, Unit>(name: 'lastSync');
  static const googleIdToken = PrefKey<String, Unit>(name: 'googleIdToken');
  static const isFirstLaunch = PrefKey<bool, Unit>(name: 'isFirstLaunch');
  static const orderedIds = PrefKey<List<String>, String>(name: 'orderedIds');
  static const doneToday = PrefKey<int, Unit>(name: 'doneToday');
  static const user = PrefKey<User, Unit>(name: 'user', fromJson: User.fromJson);

  static const activityLogs = PrefKey<List<ActivityLog>, ActivityLog>(
    fromJson: ActivityLog.fromJson,
    name: 'activityLogs',
  );

  // Map of exerciseType -> bool indicating if description has been shown already
  static const exercisesSeen = PrefKey<Map<String, bool>, Unit>(name: 'exercisesSeen');

  /// [userEmail] is optional because it is not always available if the user is not logged in
  static PrefKey<Progress, Unit> currProgress({String? userEmail}) {
    final lastLoggedInEmail = SharedPref.get(PrefKey.user)?.email;

    return PrefKey<Progress, Unit>(
      fromJson: Progress.fromJson,
      name: 'currProgress_${userEmail ?? lastLoggedInEmail ?? 'guest'}',
    );
  }

  static PrefKey<String, Unit> eTag(String id) => PrefKey<String, Unit>(name: 'eTag_$id');
}

class DestructedKey {
  final String key;
  final dynamic Function(Map<String, dynamic> json)? fromJson;

  DestructedKey({required this.key, this.fromJson});
}

class SharedPref {
  static late SharedPreferences _pref;

  static Future<void> init() async {
    _pref = await SharedPreferences.getInstance();
  }

  static DestructedKey _destructKey<ST, LT, K extends PrefKey<ST, LT>>(K prefKey) {
    final fromJson = prefKey.fromJson;
    final key = prefKey.name;

    return DestructedKey(key: key, fromJson: fromJson);
  }

  static ST? get<ST, LT>(PrefKey<ST, LT> prefKey) {
    final destructedKey = _destructKey(prefKey);

    dynamic result;
    try {
      final raw = _pref.getString(destructedKey.key);

      if (raw == null) return null;

      if (ST == String) {
        result = raw;
      } else if (ST == int) {
        result = int.tryParse(raw);
      } else if (ST == double) {
        result = double.tryParse(raw);
      } else if (ST == bool) {
        result = raw == 'true';
      } else {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          if (destructedKey.fromJson != null) {
            result = decoded.map((e) => destructedKey.fromJson!(e)).toList().cast<LT>();
          } else {
            result = List.from(decoded).cast<LT>();
          }
        } else if (decoded is Map) {
          result =
              destructedKey.fromJson != null
                  ? destructedKey.fromJson!(decoded as Map<String, dynamic>)
                  : Map.from(decoded);
        } else {
          throw UnsupportedError("Cannot decode value for ${destructedKey.key}");
        }
      }

      return result as ST;
    } catch (e) {
      developer.log(e.toString(), name: 'SharedPref');
      rethrow;
    }
  }

  static Future<void> store<ST, LT, K extends PrefKey<ST, LT>>(K prefKey, ST value) async {
    final destructedKey = _destructKey(prefKey);

    dynamic validVal;
    try {
      if (isPrimitive(value)) {
        validVal = value.toString();
      } else if (value is Map) {
        validVal = jsonEncode(value);
      } else if (isListOfPrimitives(value)) {
        validVal = jsonEncode(value);
      } else if (hasToJson(value)) {
        validVal = jsonEncode((value as dynamic).toJson());
      } else if (value is List && hasToJson(value.first)) {
        final list = value.map((e) => (e as dynamic).toJson()).toList();
        validVal = jsonEncode(list);
      } else {
        throw UnsupportedError(
          " SharedPred error(Unsupported type): ${value.runtimeType}: ${ST.toString()} if it is custom class consider implementing SharedPrefClass class",
        );
      }

      await _pref.setString(destructedKey.key, validVal);
    } catch (e) {
      developer.log(e.toString(), name: 'SharedPref');
      rethrow;
    }
  }

  static Future<void> pushValue<LT, ST extends List<LT>, K extends PrefKey<ST, LT>>(K prefKey, LT newValue) async {
    final existing = get(prefKey);
    dynamic updated;

    if (existing == null) {
      updated = [newValue];
    } else {
      existing.add(newValue);
      updated = existing;
    }

    await store(prefKey, updated);
  }

  static Future<void> removeValue<ST, LT, K extends PrefKey<ST, LT>>(K prefKey) async {
    await _pref.remove(prefKey.name);
  }

  static Future<void> copyWith<ST, LT, K extends PrefKey<ST, LT>>(K key, ST value) async {
    try {
      final oldValue = get(key);
      final Map oldValueMap;
      final Map valueMap;

      if (value is Map) {
        oldValueMap = oldValue is Map ? oldValue : {};
        valueMap = value;
      } else if (hasToJson(value)) {
        oldValueMap = hasToJson(oldValue) ? (oldValue as dynamic).toJson() : {};
        valueMap = (value as dynamic).toJson();
      } else {
        throw 'Unsupported type for copyWith in SharedPref';
      }

      final merged = oldValueMap.map(
        (k, v) => valueMap.containsKey(k) && valueMap[k] != null ? MapEntry(k, valueMap[k]) : MapEntry(k, v),
      );

      if (key.fromJson != null) {
        final updatedObj = key.fromJson!(Map<String, dynamic>.from(merged));
        await store(key, updatedObj);
      } else {
        await store<ST, LT, K>(key, merged as ST);
      }
    } catch (e) {
      developer.log(e.toString());
    }
  }
}
