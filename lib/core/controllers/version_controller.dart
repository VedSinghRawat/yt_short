import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:myapp/constants/constants.dart';

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
  return VersionController();
});

class VersionController extends StateNotifier<VersionState> {
  VersionController() : super(const VersionState());

  Future<String?> checkVersion(BuildContext context) async {
    // If user has skipped the update, proceed to app
    if (state.hasSkippedUpdate) {
      return '/';
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // Compare versions using semantic versioning
    if (_isVersionLower(currentVersion, kRequiredAppVersion)) {
      return '/version/required';
    }

    if (_isVersionLower(currentVersion, kSuggestedAppVersion)) {
      return '/version/suggest';
    }

    return '/';
  }

  void skipUpdate() {
    state = state.copyWith(hasSkippedUpdate: true);
  }

  bool _isVersionLower(String current, String target) {
    final currentParts = current.split('.').map(int.parse).toList();
    final targetParts = target.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final currentNum = i < currentParts.length ? currentParts[i] : 0;
      final targetNum = i < targetParts.length ? targetParts[i] : 0;

      if (currentNum < targetNum) return true;
      if (currentNum > targetNum) return false;
    }

    return false;
  }
}
