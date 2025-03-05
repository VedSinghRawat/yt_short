import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;
import 'package:package_info_plus/package_info_plus.dart';

// Global package info that will be set during initialization
PackageInfo? globalPackageInfo;

class InitializeService {
  UserController userController;
  PackageInfo packageInfo;

  InitializeService({required this.userController, required this.packageInfo});

  Future<void> initialize() async {
    try {
      // Set global package info for use throughout the app
      globalPackageInfo = packageInfo;

      final currProgress = await SharedPref.getCurrProgress();
      final apiUser = await userController.getCurrentUser();

      if (currProgress == null && apiUser == null) return;

      final localLastModified = currProgress?['modified'] ?? 0;
      final apiLastModified =
          apiUser != null ? DateTime.parse(apiUser.modified).millisecondsSinceEpoch : 0;

      localLastModified > apiLastModified
          ? await userController.progressSync(currProgress!['level'], currProgress['subLevel'])
          : await SharedPref.setCurrProgress(level: apiUser?.level, subLevel: apiUser?.subLevel);
    } catch (e, stackTrace) {
      developer.log('Error during initialize', error: e.toString(), stackTrace: stackTrace);
    }
  }
}

final initializeServiceProvider = FutureProvider<InitializeService>((ref) async {
  // Load package info early
  final packageInfo = await PackageInfo.fromPlatform();

  final service = InitializeService(
    userController: ref.read(userControllerProvider.notifier),
    packageInfo: packageInfo,
  );

  await service.initialize();
  return service;
});
