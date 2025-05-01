import 'package:myapp/services/file/file_service.dart';

class PathService {
  static String get levelsDocDir => '${FileService.documentsDirectory.path}/levels';
  static String get levelsCacheDir => '${FileService.cacheDirectory.path}/levels';

  static String level(String levelId) => '$levelsDocDir/$levelId';

  static String levelJsonFull(String levelId) => '${FileService.documentsDirectory.path}${levelJson(levelId)}';

  static String orderedIds() => '/levels/ordered_ids.json';

  static String levelJson(String levelId) => '/levels/$levelId/data.json';

  static String levelVideosDir(String levelId) => '/levels/$levelId/videos';
  static String levelAudiosDir(String levelId) => '/levels/$levelId/audios';

  static String video(String levelId, String videoFilename) => '${levelVideosDir(levelId)}/$videoFilename.mp4';

  static String levelVideosDirLocal(String levelId) =>
      '${FileService.documentsDirectory.path}${levelVideosDir(levelId)}';

  static String videoLocal(String levelId, String videoFilename) =>
      '${FileService.documentsDirectory.path}${video(levelId, videoFilename)}';

  static String get dialogueAudioDir => '${FileService.documentsDirectory.path}/dialogues/audios';
  static String get dialogueDataDir => '${FileService.documentsDirectory.path}/dialogues/data';

  static String dialogueAudio(String fileName) => '$dialogueAudioDir/$fileName.mp3';

  static String dialogueTempZip(int zipNum) => '$dialogueAudioDir/zips/$zipNum.zip';

  static String audio(String levelId, String audioFilename) => '${levelAudiosDir(levelId)}/$audioFilename.mp3';

  static String audioLocal(String levelId, String audioFilename) =>
      '${FileService.documentsDirectory.path}${audio(levelId, audioFilename)}';
}
