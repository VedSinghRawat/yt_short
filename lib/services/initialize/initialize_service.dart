import 'dart:async';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/apis/initialize/initialize_api.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/info/info_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'dart:developer' as developer;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'initialize_service.g.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class InitializeService {
  InitializeAPI initializeAPI;
  LevelController levelController;
  UserController userController;
  Ref ref;

  InitializeService({
    required this.ref,
    required this.initializeAPI,
    required this.levelController,
    required this.userController,
  });

  Future<void> initialize() async {
    try {
      // order matters
      await SharedPref.init(); // first init shared pref
      await InfoService.init(); // then init info service
      await initialApiCall(); // then call api because it depends on info service

      await Future.wait([
        storeCyId(), // depend on user
        FileService.init(),
        levelController.getOrderedIds(),
        handleDeepLinking(), // deep linking depends on user
      ]);

      final currProgress = SharedPref.get(
        PrefKey.currProgress(userEmail: ref.read(userControllerProvider).currentUser?.email),
      );

      final apiUser = ref.read(userControllerProvider).currentUser;
      if (currProgress == null && apiUser == null) return;

      final localLastModified = currProgress?.modified ?? 0;
      final apiLastModified = apiUser != null ? apiUser.lastProgress : 0;
      final localIsNewer = localLastModified > apiLastModified && currProgress?.levelId != null;

      if (localIsNewer) {
        await userController.sync(currProgress!.levelId!, currProgress.subLevel!);
      } else {
        final progress = Progress(
          level: apiUser?.level,
          levelId: apiUser?.levelId,
          maxLevel: apiUser?.maxLevel,
          maxSubLevel: apiUser?.maxSubLevel,
          subLevel: apiUser?.subLevel,
          modified: apiUser != null ? DateTime.parse(apiUser.modified).millisecondsSinceEpoch : null,
        );

        final uiController = ref.read(uIControllerProvider.notifier);
        await uiController.storeProgress(progress, userEmail: apiUser?.email);
      }

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
    if (cyId == null || cyId == AppConstants.kDefaultReferrer) return;

    await SharedPref.store(PrefKey.cyId, cyId);
  }

  Future<void> handleDeepLinking() async {
    if (SharedPref.get(PrefKey.cyId) != null) return;

    final appLinks = AppLinks();

    StreamSubscription<Uri>? appLinkSubscription;

    appLinkSubscription = appLinks.uriLinkStream.listen((uri) async {
      final pathSegments = uri.pathSegments;

      var cyId = pathSegments.length > 1 ? pathSegments[1] : pathSegments[0];

      await SharedPref.store(PrefKey.cyId, cyId);

      final context = navigatorKey.currentContext;

      if (context != null && context.mounted) {
        await appLinkSubscription?.cancel();
        if (context.mounted) {
          await GoRouter.of(context).push(Routes.deepLinking);
        }
      }
    });
  }

  Future<bool> initialApiCall() async {
    try {
      final version = InfoService.packageInfo.version;

      final initialData = await initializeAPI.initialize(version);

      if (initialData.user != null) {
        final u = userController.userFromDTO(initialData.user!);
        // Store doneToday from API user
        await SharedPref.store(PrefKey.doneToday, initialData.user!.doneToday);

        // Store last logged in email
        await userController.updateCurrentUser(u);
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      developer.log('Error during initialize', error: e.toString(), stackTrace: stackTrace);
      return false;
    }
  }
}

@riverpod
Future<InitializeService> initializeService(Ref ref) async {
  final service = InitializeService(
    ref: ref,
    initializeAPI: ref.watch(initializeAPIProvider),
    levelController: ref.watch(levelControllerProvider.notifier),
    userController: ref.watch(userControllerProvider.notifier),
  );

  await service.initialize();
  return service;
}
