import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'path_service.g.dart';

class PathService {
  final FileService fileService;

  PathService(this.fileService);

  String get levelsDocDirPath => '${fileService.documentsDirectory.path}/levels';
  String get levelsCacheDirPath => '${fileService.cacheDirectory.path}/levels';

  String levelPath(String levelId) {
    return '$levelsDocDirPath/$levelId';
  }

  String levelJsonFullPath(String levelId) {
    return '${fileService.documentsDirectory.path}${levelJsonPath(levelId)}';
  }

  String orderedIdsPath() => '/levels/ordered_ids.json';

  String levelJsonPath(String levelId) {
    return '/levels/$levelId/data.json';
  }

  String levelVideosPath(String levelId) {
    return '/levels/$levelId/videos';
  }

  String videoPath(String levelId, String videoFilename) {
    return '${levelVideosPath(levelId)}/$videoFilename.mp4';
  }

  String videoDirLocalPath(String levelId) {
    return '${fileService.documentsDirectory.path}${levelVideosPath(levelId)}';
  }

  String fullVideoLocalPath(String levelId, String videoFilename) {
    return '${fileService.documentsDirectory.path}${videoPath(levelId, videoFilename)}';
  }
}

@riverpod
PathService pathService(Ref ref) {
  return PathService(ref.read(fileServiceProvider));
}
