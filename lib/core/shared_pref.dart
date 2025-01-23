import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static Future<String?> _getValue(String key) async {
    final instance = await SharedPreferences.getInstance();
    return instance.getString(key);
  }

  static Future<void> _setValue(String key, String value) async {
    final instance = await SharedPreferences.getInstance();
    await instance.setString(key, value);
  }

  static Future<Map<String, dynamic>?> _getObject(String key) async {
    final value = await _getValue(key);
    if (value == null) return null;
    return jsonDecode(value);
  }

  static Future<void> _setObject(String key, Map<String, dynamic> value) async {
    final encoded = jsonEncode(value);
    await _setValue(key, encoded);
  }

  static Future<void> setProgress(int level, int subLevel) async {
    await _setObject('progress', {
      'level': level,
      'subLevel': subLevel,
    });
  }

  static Future<Map<String, dynamic>?> getProgress() async {
    final progress = await _getObject('progress');
    if (progress == null) return null;

    return {
      'level': int.parse(progress['level']),
      'subLevel': int.parse(progress['subLevel']),
    };
  }

  static Future<int> getLastSync() async {
    final lastSync = await _getValue('lastSync');
    if (lastSync == null) return 0;
    return int.parse(lastSync);
  }

  static Future<void> setLastSync(int lastSync) async {
    await _setValue('lastSync', lastSync.toString());
  }
}
