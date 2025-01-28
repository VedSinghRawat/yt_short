import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;

class InitializeService {
  UserController userController;

  InitializeService({required this.userController});

  Future<void> initialize() async {
    try {
      final localUser = await SharedPref.getUser();

      var apiUser = await userController.getCurrentUser();

      if (apiUser == null || localUser == null) return;

      final localLastModified = DateTime.parse(localUser.modified);
      final apiLastModified = DateTime.parse(apiUser.modified);

      if (localLastModified.isAfter(apiLastModified)) {
        await userController.progressSync(localUser.level, localUser.subLevel);

        apiUser = apiUser.copyWith(level: localUser.level, subLevel: localUser.subLevel);
      } else {
        SharedPref.setCurrProgress(apiUser.level, apiUser.subLevel);
      }

      await SharedPref.setUser(apiUser);
    } catch (e) {
      developer.log(e.toString());
    }
  }
}

final initializeServiceProvider = FutureProvider<InitializeService>((ref) async {
  final service = InitializeService(userController: ref.read(userControllerProvider.notifier));
  await service.initialize();
  return service;
});
