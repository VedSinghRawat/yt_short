import 'dart:convert';
import 'package:myapp/models/activity_log/activity_log.dart';
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

  static Future<void> setCurrProgress(
      {int? level, int? subLevel, int? maxLevel, int? maxSubLevel}) async {
    final currProgress = await getCurrProgress();

    await _setObject('currProgress', {
      'level': level ?? currProgress?['level'],
      'subLevel': subLevel ?? currProgress?['subLevel'],
      'modified': DateTime.now().millisecondsSinceEpoch,
      'maxLevel': maxLevel ?? currProgress?['maxLevel'],
      'maxSubLevel': maxSubLevel ?? currProgress?['maxSubLevel'],
    });
  }

  static Future<Map<String, dynamic>?> getCurrProgress() async {
    return await _getObject('currProgress');
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

  static Future<void> addActivityLog(int level, int subLevel, String email) async {
    if (email.isEmpty) return;
    var activityLogs = await _getList('activityLogs') ?? [];
    final newActivityLog = ActivityLog(
      level: level,
      subLevel: subLevel,
      userEmail: email,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    activityLogs.add(newActivityLog.toJson());
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

  static Future<void> clearAll() async {
    final instance = await SharedPreferences.getInstance();
    await instance.clear();
  }

  // Video URL caching methods
  static Future<Map<String, dynamic>?> getCachedVideoUrl(String videoId) async {
    return await _getObject('video_$videoId');
  }

  static Future<void> cacheVideoUrl(String videoId, Map<String, dynamic> data) async {
    await _setObject('video_$videoId', {
      ...data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
