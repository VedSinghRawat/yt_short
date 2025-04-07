import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InfoService {
  static final InfoService _instance = InfoService._internal();

  late final PackageInfo packageInfo;
  VersionData? versionData;

  InfoService._internal();

  static InfoService get instance => _instance;

  Future<void> init() async {
    packageInfo = await PackageInfo.fromPlatform();
  }

  Future<void> initVersionData(VersionData versionData) async {
    this.versionData = versionData;
  }
}

final infoServiceProvider = Provider<InfoService>((ref) {
  return InfoService._instance;
});

class VersionData {
  final bool closable;
  final String? content;

  VersionData({required this.closable, required this.content});
}
