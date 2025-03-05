import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/version_api.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/services/initialize_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// State class to track version check state
class VersionState {
  final bool checkedVersion;

  const VersionState({this.checkedVersion = false});

  VersionState copyWith({bool? checkedVersion}) {
    return VersionState(checkedVersion: checkedVersion ?? this.checkedVersion);
  }
}

// Remove the separate packageInfoProvider as we now use globalPackageInfo
final versionControllerProvider = StateNotifierProvider<VersionController, VersionState>((ref) {
  // Wait for initialization to complete
  ref.watch(initializeServiceProvider);
  // Use the global package info that's guaranteed to be loaded
  return VersionController(ref.read(versionAPIService), globalPackageInfo!);
});

class VersionController extends StateNotifier<VersionState> {
  final VersionAPI _versionAPI;
  final PackageInfo _packageInfo;

  VersionController(this._versionAPI, this._packageInfo) : super(const VersionState());

  Future<VersionType?> checkVersion(BuildContext context) async {
    try {
      if (state.checkedVersion) {
        return null;
      }

      return await _versionAPI.getVersion(_packageInfo.version);
    } catch (e) {
      developer.log(e.toString());
      return null;
    } finally {
      if (mounted && !state.checkedVersion) {
        doneVersionCheck();
      }
    }
  }

  void doneVersionCheck() {
    state = state.copyWith(checkedVersion: true);
  }

  Future<void> openStore(BuildContext context) async {
    final platformUrl = Platform.isAndroid
        ? kPlayStoreBaseUrl + _packageInfo.packageName
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
