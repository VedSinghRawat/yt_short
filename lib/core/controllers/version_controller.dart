import 'dart:developer' as developer;
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
  final bool checkedVersion;

  const VersionState({
    this.checkedVersion = false,
  });

  VersionState copyWith({
    bool? checkedVersion,
  }) {
    return VersionState(
      checkedVersion: checkedVersion ?? this.checkedVersion,
    );
  }
}

final versionControllerProvider = StateNotifierProvider<VersionController, VersionState>((ref) {
  return VersionController(ref.read(versionAPIService));
});

class VersionController extends StateNotifier<VersionState> {
  final VersionAPI _versionAPI;

  late PackageInfo packageInfo;

  VersionController(this._versionAPI) : super(const VersionState()) {
    _initPackageInfo().catchError((e) {
      developer.log(e);
    });
  }

  Future<void> _initPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
  }

  Future<VersionType?> checkVersion(BuildContext context) async {
    try {
      if (state.checkedVersion) {
        return null;
      }

      final currentVersion = packageInfo.version;

      return await _versionAPI.getVersion(currentVersion);
    } catch (e) {
      return null;
    } finally {
      if (!state.checkedVersion) {
        doneVersionCheck();
      }
    }
  }

  void doneVersionCheck() {
    state = state.copyWith(checkedVersion: true);
  }

  Future<void> openStore(BuildContext context) async {
    final platformUrl = Platform.isAndroid
        ? kPlayStoreBaseUrl + packageInfo.packageName
        : kAppStoreBaseUrl + kIOSAppId;

    final Uri url = Uri.parse(Uri.encodeFull(platformUrl));

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return;
    }

    showErrorSnackBar(context, 'Could not open the store');
  }
}
