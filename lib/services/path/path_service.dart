enum AssetType {
  video('video.mp4'),
  audio('audio.mp3'),
  image('image.jpg'),
  data('data.json');

  const AssetType(this.filename);
  final String filename;
}

class PathService {
  static String orderedIds() => '/levels/ordered_ids.json';

  static String levelDir(String levelId) => '/levels/$levelId';
  static String levelJson(String levelId) => '${levelDir(levelId)}/data.json';

  static String sublevelDir(String levelId, String sublevelId) => '${levelDir(levelId)}/sub_levels/$sublevelId';
  static String sublevelAsset(String levelId, String sublevelId, AssetType type) =>
      '${sublevelDir(levelId, sublevelId)}/${type.filename}';

  static String dialogueDir(String dialogueId) => '/dialogues/$dialogueId';
  static String dialogueAsset(String dialogueId, AssetType type) => '${dialogueDir(dialogueId)}/${type.filename}';

  static String dialogueZip(int zipNum) => '/dialogues/zips/$zipNum.zip';
  static String dialogueTempZip(int zipNum) => '/temp/${dialogueZip(zipNum)}';
}
