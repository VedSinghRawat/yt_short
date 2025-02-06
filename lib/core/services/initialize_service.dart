import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;

class InitializeService {
  UserController userController;

  InitializeService({required this.userController});

  Future<void> initialize() async {
    try {
      final currProgress = await SharedPref.getCurrProgress();
      final apiUser = await userController.getCurrentUser();
      developer.log('currProgress: $currProgress');
      developer.log('apiUser: ${apiUser?.toJson()}');

      if (currProgress == null && apiUser == null) return;

      final localLastModified = currProgress?['modified'] ?? 0;
      final apiLastModified =
          apiUser != null ? DateTime.parse(apiUser.modified).millisecondsSinceEpoch : 0;

      localLastModified > apiLastModified
          ? await userController.progressSync(currProgress!['level'], currProgress['subLevel'])
          : await SharedPref.setCurrProgress(apiUser!.level, apiUser.subLevel);
    } catch (e, stackTrace) {
      developer.log('Error during initialize', error: e.toString(), stackTrace: stackTrace);
    }
  }
}

final initializeServiceProvider = FutureProvider<InitializeService>((ref) async {
  final service = InitializeService(userController: ref.read(userControllerProvider.notifier));
  await service.initialize();
  return service;
});
