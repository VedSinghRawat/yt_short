import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/initialize_api.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/services/info_service.dart';
import 'package:myapp/core/services/initialize_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// State class to track version check state
class VersionState {
  final String? content;
  final bool closable;

  const VersionState({this.content, this.closable = false});

  VersionState copyWith({String? content, bool? closable}) {
    return VersionState(
      content: content ?? this.content,
      closable: closable ?? this.closable,
    );
  }

  VersionState clearContent() {
    return VersionState(
      content: null,
      closable: closable,
    );
  }
}

// Remove the separate packageInfoProvider as we now use globalPackageInfo
final versionControllerProvider = StateNotifierProvider<VersionController, VersionState>((ref) {
  // Wait for initialization to complete
  ref.watch(initializeServiceProvider);
  // Use the global package info that's guaranteed to be loaded
  return VersionController(ref.read(infoServiceProvider));
});

class VersionController extends StateNotifier<VersionState> {
  final InfoService _infoService;

  VersionController(this._infoService) : super(const VersionState());

  Future<void> checkVersion(BuildContext context) async {
    try {
      final versionRes = _infoService.versionData;

      if (versionRes == null) return;

      state = state.copyWith(
        content: versionRes['content'],
        closable: versionRes['closable'],
      );
    } catch (e) {
      developer.log(e.toString());
    }
  }

  Future<void> openStore(BuildContext context) async {
    final platformUrl = Platform.isAndroid
        ? kPlayStoreBaseUrl + _infoService.packageInfo.packageName
        : kAppStoreBaseUrl + kIOSAppId;

    final Uri url = Uri.parse(Uri.encodeFull(platformUrl));

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return;
    }

    if (!context.mounted) return;

    showErrorSnackBar(context, 'Could not open the store');
  }

  // Method to dismiss the version message by clearing the content
  void dismissMessage() {
    state = state.clearContent();
  }
}
