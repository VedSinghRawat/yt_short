import 'dart:convert';
import 'dart:developer' as developer;
import 'package:fpdart/fpdart.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myapp/core/util_types/progress.dart';

import 'package:myapp/models/activity_log/activity_log.dart';

class Raw<StoredType> {
  final String key;
  StoredType Function(Map<String, dynamic>)? fromJson;

  Raw({required this.key, this.fromJson});
}

enum PrefKey<StoredType, ListItemType> {
  cyId<String, Unit>(),
  currProgress<Progress, Unit>(Progress.fromJson),
  lastSync<int, Unit>(),
  googleIdToken<String, Unit>(),
  isFirstLaunch<bool, Unit>(),
  activityLogs<List<ActivityLog>, ActivityLog>(ActivityLog.fromJson),
  orderedIds<List<String>, String>();

  final dynamic Function(Map<String, dynamic> json)? fromJson;

  const PrefKey([this.fromJson]);

  static Raw<String> eTagKey(String id) => Raw(key: 'eTagKey_$id');
}

class SharedPref {
  static late SharedPreferences _pref;

  static Future<void> init() async {
    _pref = await SharedPreferences.getInstance();
  }

  static Future<StoredType?> getValue<StoredType, ListItemType>(
    PrefKey<StoredType, ListItemType> key,
  ) async {
    return _get(key.name, key.fromJson, key.name);
  }

  static Future<StoredType?> getRawValue<StoredType, ListItemType>(Raw<StoredType> raw) async {
    return _get(raw.key, raw.fromJson, raw.key);
  }

  static StoredType? _get<StoredType, ListItemType>(
    String key,
    dynamic Function(Map<String, dynamic>)? fromJson,
    String debugKey,
  ) {
    dynamic result;
    try {
      final raw = _pref.getString(key);

      if (raw == null) return null;

      if (StoredType == String) {
        result = raw;
      } else if (StoredType == int) {
        result = int.tryParse(raw);
      } else if (StoredType == double) {
        result = double.tryParse(raw);
      } else if (StoredType == bool) {
        result = raw == 'true';
      } else {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          if (fromJson != null) {
            result = decoded.map((e) => fromJson(e)).toList();
          }

          result = List.from(decoded).cast<ListItemType>();
        } else {
          if (decoded is Map) result = Map.from(decoded);
        }

        throw UnsupportedError("Cannot decode value for $debugKey");
      }

      return result as StoredType;
    } catch (e) {
      Console.error(
        Failure(message: '$e----in key--- $key --- type is $StoredType and from json is $fromJson'),
        StackTrace.current,
      );

      rethrow;
    }
  }

  static Future<void> storeRawValue<StoredType, KeyType extends Raw<StoredType>>(
    KeyType raw,
    StoredType value,
  ) async {
    await _store(raw.key, value);
  }

  static Future<void>
      storeValue<StoredType, KeyType extends PrefKey<StoredType, ListItemType>, ListItemType>(
    KeyType key,
    StoredType value,
  ) async {
    await _store(key.name, value);
  }

  static Future<void> addValue<StoredType, ListItemType>(
    PrefKey<StoredType, ListItemType> key,
    dynamic newValue,
  ) async {
    final existing = await getValue<StoredType, ListItemType>(key);
    dynamic updated;

    if (existing is List) {
      updated = [...existing, newValue];
    } else if (existing is Map) {
      updated = {...existing, ...newValue};
    } else if (existing == null) {
      updated = newValue;
    } else {
      throw 'SharedPref: Key is not addable: expected List or Map, got \${existing.runtimeType}';
    }

    await storeValue(key, updated);
  }

  static Future<void> _store<StoredType>(String key, StoredType value) async {
    dynamic validVal;
    try {
      if (value is String || value is int || value is double || value is bool) {
        validVal = value.toString();
      } else if (_isListOfPrimitives(value)) {
        validVal = jsonEncode(value);
      } else if (value is SharedPrefClass) {
        validVal = jsonEncode(value.toJson());
      } else if (value is List && value.first is SharedPrefClass) {
        final list = value.map((e) => e.toJson()).toList();
        validVal = jsonEncode(list);
      } else {
        throw UnsupportedError(
          " SharedPred error(Unsupported type): \${value.runtimeType}: \${StoredType.toString()} if it is custom class consider implementing SharedPrefClass class",
        );
      }

      await _pref.setString(key, validVal);
    } catch (e) {
      Console.error(
        Failure(message: e.toString()),
        StackTrace.current,
      );

      rethrow;
    }
  }

  static Future<void> removeValue<StoredType, ListItemType>(
    PrefKey<StoredType, ListItemType> key,
  ) async {
    await _pref.remove(key.name);
  }

  static Future<void> removeRawValue<StoredType>(Raw<StoredType> raw) async {
    await _pref.remove(raw.key);
  }

  static Future<void> clearAll() async {
    await _pref.clear();
  }

  static bool _isListOfPrimitives(Object? value) {
    if (value is List) {
      return value.every((e) => e is String || e is int || e is double || e is bool);
    }
    return false;
  }

  static Future<void>
      copyWith<StoredType, KeyType extends PrefKey<StoredType, ListItemType>, ListItemType>(
    KeyType key,
    StoredType value,
  ) async {
    try {
      final oldValue = await getValue(key);
      final Map oldValueMap;
      final Map valueMap;

      if (value is Map) {
        oldValueMap = oldValue is Map ? oldValue : {};
        valueMap = value;
      } else if (value is SharedPrefClass) {
        oldValueMap = oldValue is SharedPrefClass ? oldValue.toJson() : {};
        valueMap = value.toJson();
      } else {
        throw 'Unsupported type for copyWith in SharedPref';
      }

      final merged = oldValueMap.map((k, v) => valueMap.containsKey(k) && valueMap[k] != null
          ? MapEntry(k, valueMap[k])
          : MapEntry(k, v));

      if (key.fromJson != null) {
        final updatedObj = key.fromJson!(Map<String, dynamic>.from(merged));
        await _store<StoredType>(key.name, updatedObj);
      } else {
        await _store<Map<String, dynamic>>(key.name, merged as Map<String, dynamic>);
      }
    } catch (e) {
      developer.log(e.toString());
    }
  }
}

abstract class SharedPrefClass {
  Map<String, dynamic> toJson();
}
