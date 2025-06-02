class PathService {
  static String orderedIds() => '/levels/ordered_ids.json';

  static String levelDir(String levelId) => '/levels/$levelId';
  static String levelJson(String levelId) => '${levelDir(levelId)}/data.json';

  static String sublevelDir(String levelId, String sublevelId) => '${levelDir(levelId)}/sub_levels/$sublevelId';
  static String sublevelVideo(String levelId, String sublevelId) => '${sublevelDir(levelId, sublevelId)}/video.mp4';
  static String sublevelAudio(String levelId, String sublevelId) => '${sublevelDir(levelId, sublevelId)}/audio.mp3';

  static String dialogueDir(String dialogueId) => '/dialogues/$dialogueId';
  static String dialogueJson(String dialogueId) => '${dialogueDir(dialogueId)}/data.json';
  static String dialogueAudio(String dialogueId) => '${dialogueDir(dialogueId)}/audio.mp3';

  static String dialogueZip(int zipNum) => '/dialogues/zips/$zipNum.zip';
  static String dialogueTempZip(int zipNum) => '/temp/${dialogueZip(zipNum)}';
}
