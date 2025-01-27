import 'dart:convert';
import 'package:myapp/models/user/user.dart';
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

  static Future<List<dynamic>?> _getList(String key) async {
    final value = await _getValue(key);
    if (value == null) return null;
    return jsonDecode(value);
  }

  static Future<void> _setObject(String key, dynamic value) async {
    final encoded = jsonEncode(value);
    await _setValue(key, encoded);
  }

  static Future<UserModel?> getUser() async {
    final user = await _getObject('user');
    if (user == null) return null;
    return UserModel.fromJson(user);
  }

  static Future<void> setUser(UserModel user) async {
    await _setObject('user', user.toJson());
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
      'level': progress['level'],
      'subLevel': progress['subLevel'],
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

  static Future<String?> getGoogleIdToken() async {
    return await _getValue('googleIdToken');
  }

  static Future<void> setGoogleIdToken(String token) async {
    await _setValue('googleIdToken', token);
  }

  static Future<void> addActivityLog(ActivityLog activityLog) async {
    var activityLogs = await _getList('activityLogs') ?? [];
    activityLogs.add(activityLog.toJson());
    await _setObject('activityLogs', activityLogs);
  }

  static Future<void> clearActivityLogs() async {
    await _setObject('activityLogs', []);
  }

  static Future<List<ActivityLog>?> getActivityLogs() async {
    final activityLogs = await _getList('activityLogs');
    if (activityLogs == null) return null;
    return activityLogs.map((e) => ActivityLog.fromJson(e)).toList();
  }
}
