import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/apis/initialize_api.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/services/info_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/features/sublevel/level_controller.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class InitializeService {
  UserControllerState userControllerState;
  InitializeAPI initializeAPI;
  LevelController levelController;
  UserController userController;

  InitializeService({
    required this.userControllerState,
    required this.initializeAPI,
    required this.levelController,
    required this.userController,
  });

  Future<void> initialize() async {
    try {
      // order matters
      await SharedPref.init(); // first init shared pref
      await InfoService.instance.init(); // then init info service
      await initialApiCall(); // then call api because it depends on info service

      await Future.wait([
        storeCyId(), // depend on user
        FileService.instance.init(),
        levelController.getOrderedIds(),
        handleDeepLinking(), // deep linking depends on user
      ]);

      final currProgress = SharedPref.get(
        PrefKey.currProgress(userEmail: userControllerState.currentUser?.email),
      );

      final apiUser = userControllerState.currentUser;
      if (currProgress == null && apiUser == null) return;

      final localLastModified = currProgress?.modified ?? 0;
      final apiLastModified =
          apiUser != null ? DateTime.parse(apiUser.modified).millisecondsSinceEpoch : 0;

      localLastModified > apiLastModified
          ? await userController.sync(currProgress!.levelId!, currProgress.subLevel!)
          : await SharedPref.copyWith(
            PrefKey.currProgress(userEmail: apiUser?.email),
            Progress(
              level: apiUser?.level,
              levelId: apiUser?.levelId,
              maxLevel: apiUser?.maxLevel,
              maxSubLevel: apiUser?.maxSubLevel,
              subLevel: apiUser?.subLevel,
            ),
          );

      await SharedPref.store(PrefKey.isFirstLaunch, false);
    } catch (e, stackTrace) {
      developer.log('Error during initialize', error: e.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> storeCyId() async {
    if (SharedPref.get(PrefKey.isFirstLaunch) == false) return;

    final referrer = await AndroidPlayInstallReferrer.installReferrer;

    final cyId = referrer.installReferrer;

    // Skip if no referrer or if it's just the default Google Play organic referrer
    if (cyId == null || cyId == kDefaultReferrer) return;

    await SharedPref.store(PrefKey.cyId, cyId);
  }

  Future<void> handleDeepLinking() async {
    if (SharedPref.get(PrefKey.cyId) != null) return;

    final appLinks = AppLinks();

    appLinks.uriLinkStream.listen((uri) async {
      final pathSegments = uri.pathSegments;

      var cyId = pathSegments.length > 1 ? pathSegments[1] : pathSegments[0];

      await SharedPref.store(PrefKey.cyId, cyId);

      final context = navigatorKey.currentContext;

      if (context != null && context.mounted) {
        await GoRouter.of(context).push(Routes.deepLinking);
      }
    });
  }

  Future<bool> initialApiCall() async {
    try {
      final version = InfoService.instance.packageInfo.version;

      final initialData = await initializeAPI.initialize(version);

      if (initialData.user != null) {
        userController.updateCurrentUser(initialData.user!);
        // Store doneToday from API user
        await SharedPref.store(PrefKey.doneToday, initialData.user!.doneToday);
        // Store last logged in email
        await SharedPref.store(PrefKey.lastLoggedInEmail, initialData.user!.email);
      }

      await InfoService.instance.initVersionData(initialData);
      return true;
    } catch (e, stackTrace) {
      developer.log('Error during initialize', error: e.toString(), stackTrace: stackTrace);
      return false;
    }
  }
}

final initializeServiceProvider = FutureProvider<InitializeService>((ref) async {
  final service = InitializeService(
    userControllerState: ref.read(userControllerProvider),
    initializeAPI: ref.read(initializeAPIService),
    levelController: ref.read(levelControllerProvider.notifier),
    userController: ref.read(userControllerProvider.notifier),
  );

  await service.initialize();
  return service;
});
