import 'dart:convert';
import 'dart:developer' as developer;
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/models/level/level.dart';
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

  static Future<void> _delete(String key) async {
    final instance = await SharedPreferences.getInstance();
    await instance.remove(key);
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

    // Merge maps but only update non-null values from progressMap
    final mergedProgressMap = {
      ...currProgressMap, // Keep existing values
      ...progressMap.map(
        (key, value) => value != null
            ? MapEntry(key, value)
            : MapEntry(
                key,
                currProgressMap[key],
              ),
      ), // Only overwrite non-null values
      'modified': DateTime.now().millisecondsSinceEpoch, // Always update timestamp
    };

    // Convert back to Progress object
    final updatedProgress = Progress.fromJson(mergedProgressMap);

    await _setObject('currProgress', updatedProgress.toJson());
  }

  static Future<void> setCyId(String cyId) async {
    await _setValue('cyId', cyId);
  }

  static Future<String?> getCyId() async {
    return await _getValue('cyId');
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

  static Future<bool> isFirstLaunch() async {
    final isFirstLaunch = await _getValue('isFirstLaunch');
    return isFirstLaunch == null || isFirstLaunch == 'true';
  }

  static Future<void> setIsFirstLaunch(bool isFirstLaunch) async {
    await _setValue('isFirstLaunch', isFirstLaunch.toString());
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

  static Future<void> storeETag(String id, String eTag) async {
    await _setValue('eTag_$id', eTag);
  }

  static Future<String?> getETag(String id) async {
    return await _getValue('eTag_$id');
  }

  static Future<List<String>?> getOrderedIds() async {
    final ids = await _getList('orderedIds');

    if (ids == null) {
      return null;
    }

    return List.castFrom<dynamic, String>(ids);
  }

  static Future<LevelDTO?> getLevelDTO(String id) async {
    final json = await _getObject('leveldto_$id');

    if (json == null) return null;

    return LevelDTO.fromJson(json);
  }

  static Future<void> setLevelDTO(LevelDTO levelDTO) async {
    await _setObject('leveldto_${levelDTO.id}', levelDTO.toJson());
  }

  static Future<void> deleteLevelDTO(String id) async {
    await _delete('leveldto_$id');
  }

  static setOrderedIds(List<String> orderedIds) async {
    return await _setObject(
      'orderedIds',
      orderedIds,
    );
  }
}
