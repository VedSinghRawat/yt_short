import 'package:myapp/core/services/file_service.dart';

class PathService {
  static String get levelsDocDirPath => '${FileService.documentsDirectory.path}/levels';
  static String get levelsCacheDirPath => '${FileService.cacheDirectory.path}/levels';

  static String levelPath(String levelId) => '$levelsDocDirPath/$levelId';

  static String levelJsonFullPath(String levelId) => '${FileService.documentsDirectory.path}${levelJsonPath(levelId)}';

  static String orderedIdsPath() => '/levels/ordered_ids.json';

  static String levelJsonPath(String levelId) => '/levels/$levelId/data.json';

  static String levelVideosDirPath(String levelId) => '/levels/$levelId/videos';
  static String levelAudiosDirPath(String levelId) => '/levels/$levelId/audios';

  static String videoPath(String levelId, String videoFilename) => '${levelVideosDirPath(levelId)}/$videoFilename.mp4';

  static String levelVideosDirLocalPath(String levelId) =>
      '${FileService.documentsDirectory.path}${levelVideosDirPath(levelId)}';

  static String videoLocalPath(String levelId, String videoFilename) =>
      '${FileService.documentsDirectory.path}${videoPath(levelId, videoFilename)}';

  static String get dialogueAudioDirPath => '${FileService.documentsDirectory.path}/dialogue/audios';

  static String dialogueAudioPath(String fileName) => '$dialogueAudioDirPath/$fileName';

  static String dialogueTempZipPath(int zipNum) => '$dialogueAudioDirPath/zips/$zipNum.zip';

  static String audioPath(String levelId, String audioFilename) => '${levelAudiosDirPath(levelId)}/$audioFilename.mp3';

  static String audioLocalPath(String levelId, String audioFilename) =>
      '${FileService.documentsDirectory.path}${audioPath(levelId, audioFilename)}';
}
