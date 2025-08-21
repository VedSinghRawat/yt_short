import 'dart:async';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/apis/initialize/initialize_api.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/services/cleanup/cleanup_service.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:developer' as developer;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/core/error/api_error.dart';

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

      await Future.wait([FileService.init(), levelController.getOrderedIds()]);

      await initialApiCall(); // depends on info service & levelController (orderedIds)
      await Future.wait([storeCyId(), handleDeepLinking()]); // depends on user

      final currProgress = SharedPref.get(
        PrefKey.currProgress(userEmail: ref.read(userControllerProvider.notifier).getUser()?.email),
      );

      final apiUser = ref.read(userControllerProvider.notifier).getUser();

      if (currProgress == null && apiUser == null) {
        return;
      }

      final localLastModified = currProgress?.modified ?? 0;
      final apiLastModified = apiUser != null ? apiUser.lastProgress : 0;

      final localIsNewer = localLastModified > apiLastModified && currProgress?.levelId != null;

      if (localIsNewer) {
        final error = await userController.sync(currProgress!.levelId!, currProgress.subLevel!);
        if (error != null) {
          developer.log('Error syncing user progress: ${error.message}', error: error.trace);
        }
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

      ref
          .read(storageCleanupServiceProvider)
          .cleanLocalFiles(SharedPref.get(PrefKey.currProgress(userEmail: apiUser?.email))?.levelId ?? '')
          .ignore();
    } catch (e, stackTrace) {
      developer.log('Error during initialize', error: e.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> storeCyId() async {
    if (SharedPref.get(PrefKey.isFirstLaunch) == false) return;

    final referrer = await AndroidPlayInstallReferrer.installReferrer;
    final cyId = referrer.installReferrer;
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

  Future<APIError?> initialApiCall() async {
    try {
      final version = await PackageInfo.fromPlatform();

      final initialData = await initializeAPI.initialize(version.version);

      if (initialData.user != null) {
        final u = userController.userFromDTO(initialData.user!);
        // Store doneToday from API user
        await SharedPref.store(PrefKey.doneToday, initialData.user!.doneToday);

        // Store last logged in email
        await userController.updateCurrentUser(u);
        return null; // Success
      }

      return APIError(message: 'No user data received', trace: StackTrace.current);
    } catch (e, stackTrace) {
      developer.log('Error during initialize', error: e.toString(), stackTrace: stackTrace);
      return APIError(message: e.toString(), trace: stackTrace);
    }
  }
}

@riverpod
Future<InitializeService> initializeService(Ref ref) async {
  final service = InitializeService(
    ref: ref,
    initializeAPI: ref.read(initializeAPIProvider),
    levelController: ref.read(levelControllerProvider.notifier),
    userController: ref.read(userControllerProvider.notifier),
  );

  await service.initialize();
  return service;
}
