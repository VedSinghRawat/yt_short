import 'dart:convert';
import 'dart:developer' as developer;
import 'package:fpdart/fpdart.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/models/level/level.dart';
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

  static Raw<LevelDTO> levelDTOKey(String id) => Raw(
        key: "levelDto_$id",
        fromJson: LevelDTO.fromJson,
      );
}

class SharedPref {
  static SharedPreferences? _pref;

  static Future<void> init() async {
    _pref = await SharedPreferences.getInstance();
  }

  static Future<StoredType?> getValue<StoredType, ListItemType>(
      PrefKey<StoredType, ListItemType> key) async {
    return _get<StoredType, ListItemType>(key.name, key.fromJson, key.name);
  }

  static Future<StoredType?> getRawValue<StoredType, ListItemType>(Raw<StoredType> raw) async {
    return _get<StoredType, ListItemType>(raw.key, raw.fromJson, raw.key);
  }

  static StoredType? _get<StoredType, ListItemType>(
    String key,
    dynamic Function(Map<String, dynamic>)? fromJson,
    String debugKey,
  ) {
    try {
      if (_pref == null) return null;

      final raw = _pref!.getString(key);

      if (raw == null) return null;

      if (StoredType == String) return raw as StoredType;
      if (StoredType == int) return int.tryParse(raw) as StoredType?;
      if (StoredType == double) return double.tryParse(raw) as StoredType?;
      if (StoredType == bool) return (raw == 'true') as StoredType;

      final decoded = jsonDecode(raw);

      if (fromJson != null && decoded is! List) {
        return fromJson(decoded);
      }

      if (decoded is List) {
        if (fromJson != null) {
          return decoded.map((e) => fromJson(e)).toList() as StoredType;
        }

        return List.from(decoded).cast<ListItemType>() as StoredType;
      }

      if (decoded is Map) return Map.from(decoded) as StoredType;

      throw UnsupportedError("Cannot decode value for $debugKey");
    } catch (e) {
      Console.error(
        Failure(message: e.toString()),
        StackTrace.current,
      );

      rethrow;
    }
  }

  static Future<void> storeRawValue<StoredType, KeyType extends Raw<StoredType>>(
      KeyType raw, StoredType value) async {
    await _store(raw.key, value);
  }

  static Future<void>
      storeValue<StoredType, KeyType extends PrefKey<StoredType, ListItemType>, ListItemType>(
          KeyType key, StoredType value) async {
    if (_pref == null) return;

    await _store<StoredType>(key.name, value);
  }

  static Future<void> addValue<StoredType, ListItemType>(
      PrefKey<StoredType, ListItemType> key, dynamic newValue) async {
    final existing = await getValue<StoredType, ListItemType>(key);

    if (existing is List) {
      final updated = [...existing, newValue] as StoredType;

      await storeValue<StoredType, PrefKey<StoredType, ListItemType>, ListItemType>(key, updated);
    } else if (existing is Map) {
      if (newValue is! Map) throw 'Value must be a Map to merge with existing Map';

      final updated = {...existing, ...newValue} as StoredType;

      await storeValue<StoredType, PrefKey<StoredType, ListItemType>, ListItemType>(key, updated);
    } else {
      throw 'SharedPref: Key is not addable: expected List or Map, got \${existing.runtimeType}';
    }
  }

  static Future<void> _store<StoredType>(String key, StoredType value) async {
    try {
      if (value is String || value is int || value is double || value is bool) {
        await _pref!.setString(key, value.toString());
      } else if (_isListOfPrimitives(value)) {
        await _pref!.setString(key, jsonEncode(value));
      } else if (value is SharedPrefClass) {
        await _pref!.setString(key, jsonEncode(value.toJson()));
      } else if (value is List && value.first is SharedPrefClass) {
        final list = value.map((e) => (e as SharedPrefClass).toJson()).toList();
        await _pref!.setString(key, jsonEncode(list));
      } else {
        throw UnsupportedError(
          " SharedPred error(Unsupported type): \${value.runtimeType}: \${StoredType.toString()} if it is custom class consider implementing SharedPrefClass class",
        );
      }
    } catch (e) {
      Console.error(
        Failure(message: e.toString()),
        StackTrace.current,
      );

      rethrow;
    }
  }

  static Future<void> removeValue<StoredType, ListItemType>(
      PrefKey<StoredType, ListItemType> key) async {
    if (_pref == null) return;
    await _pref!.remove(key.name);
  }

  static Future<void> removeRawValue<StoredType>(Raw<StoredType> raw) async {
    if (_pref == null) return;
    await _pref!.remove(raw.key);
  }

  static Future<void> clearAll() async {
    if (_pref == null) return;
    await _pref!.clear();
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
