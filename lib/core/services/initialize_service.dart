import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/apis/initialize_api.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/services/info_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/features/sublevel/ordered_ids_notifier.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;

import 'package:path_provider/path_provider.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class InitializeService {
  UserController userController;
  InitializeAPI initializeAPI;
  OrderedIdsNotifier orderedIdNotifier;

  InitializeService({
    required this.userController,
    required this.initializeAPI,
    required this.orderedIdNotifier,
  });

  Future<void> clearAppCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
    } catch (e) {
      developer.log('Unable to kill cache duo to $e');
    }
  }

  Future<void> initialize() async {
    try {
      await SharedPref.init();
      await handleDeepLinking();
      await storeCyId();
      await FileService.instance.init();
      await InfoService.instance.init();
      await clearAppCache();
      await orderedIdNotifier.getOrderedIds();

      await initializeVersion();

      final currProgress = SharedPref.get(PrefKey.currProgress);
      final apiUser = await userController.getCurrentUser();

      if (currProgress == null && apiUser == null) return;

      final localLastModified = currProgress?.modified ?? 0;
      final apiLastModified =
          apiUser != null ? DateTime.parse(apiUser.modified).millisecondsSinceEpoch : 0;

      localLastModified > apiLastModified
          ? await userController.sync(currProgress!.levelId!, currProgress.subLevel!)
          : await SharedPref.copyWith(
              PrefKey.currProgress,
              Progress(
                level: apiUser?.level,
                levelId: apiUser?.levelId,
                maxLevel: apiUser?.maxLevel,
                maxSubLevel: apiUser?.maxSubLevel,
                subLevel: apiUser?.subLevel,
                modified: apiLastModified,
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

    if (cyId == null) return;

    await SharedPref.store(PrefKey.cyId, cyId);
  }

  Future<void> handleDeepLinking() async {
    if (SharedPref.get(PrefKey.cyId) != null) return;

    final appLinks = AppLinks();

    appLinks.uriLinkStream.listen((uri) async {
      final pathSegments = uri.pathSegments;

      var cyId = pathSegments.length > 1 ? pathSegments[1] : pathSegments[0];

      await SharedPref.store(PrefKey.cyId, cyId);
      developer.log('Deep linking: $cyId');

      final context = navigatorKey.currentContext;

      if (context != null && context.mounted) {
        await GoRouter.of(context).push(Routes.deepLinked);
      }
    });
  }

  Future<void> initializeVersion() async {
    final version = InfoService.instance.packageInfo.version;

    final versionDataEither = await initializeAPI.initialize(version);

    switch (versionDataEither) {
      case Left(value: final l):
        developer.log(l.toString());
      case Right(value: final r):
        await InfoService.instance.initVersionData(r);
    }
  }
}

final initializeServiceProvider = FutureProvider<InitializeService>((ref) async {
  final service = InitializeService(
    userController: ref.read(userControllerProvider.notifier),
    initializeAPI: ref.read(initializeAPIService),
    orderedIdNotifier: ref.read(orderedIdsNotifierProvider.notifier),
  );

  await service.initialize();
  return service;
});
