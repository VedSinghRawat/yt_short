import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/version_api.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// State class to track version check state
class VersionState {
  final bool hasSkippedUpdate;

  const VersionState({
    this.hasSkippedUpdate = false,
  });

  VersionState copyWith({
    bool? hasSkippedUpdate,
  }) {
    return VersionState(
      hasSkippedUpdate: hasSkippedUpdate ?? this.hasSkippedUpdate,
    );
  }
}

final versionControllerProvider = StateNotifierProvider<VersionController, VersionState>((ref) {
  return VersionController(ref.read(versionAPIService));
});

class VersionController extends StateNotifier<VersionState> {
  VersionController(this._versionAPI) : super(const VersionState());

  final VersionAPI _versionAPI;

  Future<String?> checkVersion(BuildContext context) async {
    try {
      if (state.hasSkippedUpdate) {
        return Routes.home;
      }

      final packageInfo = await PackageInfo.fromPlatform();

      final currentVersion = packageInfo.version;

      final versionType = await _versionAPI.getVersion(currentVersion);

      if (versionType == VersionType.required) {
        return Routes.versionRequired;
      }

      if (versionType == VersionType.suggested) {
        return Routes.versionSuggest;
      }

      return Routes.home;
    } catch (e) {
      return Routes.home;
    }
  }

  void skipUpdate() {
    state = state.copyWith(hasSkippedUpdate: true);
  }

  Future<void> openStore(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();

    final platformUrl = Platform.isAndroid
        ? kPlayStoreBaseUrl + packageInfo.packageName
        : kAppStoreBaseUrl + kIOSAppId;

    final Uri url = Uri.parse(Uri.encodeFull(platformUrl));

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return;
    }

    if (!context.mounted) return;

    showErrorSnackBar(context, 'Could not open the store');
  }
}
