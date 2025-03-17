import 'dart:convert';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/models/Level/level.dart';
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

  static Future<void> _setObject(String key, Object value) async {
    final encoded = jsonEncode(value);
    await _setValue(key, encoded);
  }

  static Future<void> setCurrProgress(Progress progress) async {
    final currProgress = await getCurrProgress();

    // Convert both to maps
    final progressMap = progress.toJson();
    final currProgressMap = currProgress?.toJson() ?? {};

    // Merge maps: Use existing values if they are null
    final mergedProgressMap = {
      ...currProgressMap, // Previous progress values
      ...progressMap, // New values (overwriting non-null values)
      'modified': DateTime.now().millisecondsSinceEpoch, // Always update timestamp
    };

    // Convert back to Progress object
    final updatedProgress = Progress.fromJson(mergedProgressMap);

    await _setObject('currProgress', updatedProgress.toJson());
  }

  static Future<Progress?> getCurrProgress() async {
    final data = await _getObject('currProgress');

    if (data == null) return null;

    return Progress.fromJson(data);
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

  static Future<List<Level>> getCachedLevels() async {
    final cachedLevels = await _getList('cachedLevels');

    return cachedLevels?.map((e) => Level.fromJson(e)).toList() ?? [];
  }

  static Future<void> addCachedLevel(Level level) async {
    final cachedLevels = await getCachedLevels();

    cachedLevels.add(level);

    await _setObject('cachedLevels', cachedLevels);
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

  static Future<void> storeETag(String levelId, int zipId, String eTag) async {
    await _setValue('eTag_$levelId$zipId', eTag);
  }

  static Future<String?> getETag(String levelId, int zipId) async {
    return await _getValue('eTag_$levelId$zipId');
  }
}
