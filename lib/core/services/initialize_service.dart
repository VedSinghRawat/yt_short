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
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class InitializeService {
  UserController userController;
  InitializeAPI initializeAPI;

  InitializeService({
    required this.userController,
    required this.initializeAPI,
  });

  Future<void> initialize() async {
    try {
      await FileService.instance.init();
      await InfoService.instance.init();

      await storeCyId();

      await handleDeepLinking();
      await initializeVersion();

      final currProgress = await SharedPref.getCurrProgress();
      final apiUser = await userController.getCurrentUser();

      if (currProgress == null && apiUser == null) return;

      final localLastModified = currProgress?.modified ?? 0;
      final apiLastModified =
          apiUser != null ? DateTime.parse(apiUser.modified).millisecondsSinceEpoch : 0;

      localLastModified > apiLastModified
          ? await userController.progressSync(currProgress!.level!, currProgress.subLevel!)
          : await SharedPref.setCurrProgress(
              Progress(
                level: apiUser?.level,
                subLevel: apiUser?.subLevel,
                modified: apiLastModified,
              ),
            );

      await SharedPref.setIsFirstLaunch(false);
    } catch (e, stackTrace) {
      developer.log('Error during initialize', error: e.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> storeCyId() async {
    if (!await SharedPref.isFirstLaunch()) return;

    final referrer = await AndroidPlayInstallReferrer.installReferrer;

    final cyId = referrer.installReferrer;

    if (cyId == null) return;

    await SharedPref.setCyId(cyId);
  }

  Future<void> handleDeepLinking() async {
    final appLinks = AppLinks();

    appLinks.uriLinkStream.listen((uri) async {
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2 && pathSegments[0] == 'cyid') {
        final cyId = pathSegments[1];
        await SharedPref.setCyId(cyId);
        developer.log('Deep linking: $cyId');

        final context = navigatorKey.currentContext;

        if (context != null && context.mounted) {
          await GoRouter.of(context).pushNamed(Routes.deepLinked);
        }
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
  );

  await service.initialize();
  return service;
});
