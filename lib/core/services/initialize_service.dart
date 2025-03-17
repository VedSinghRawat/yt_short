import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/initialize_api.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/services/info_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;

class InitializeService {
  UserController userController;
  InitializeAPI initializeAPI;

  InitializeService({required this.userController, required this.initializeAPI});

  Future<void> initialize() async {
    try {
      await FileService.instance.init();
      await InfoService.instance.init();

      await initializeVersion();

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
