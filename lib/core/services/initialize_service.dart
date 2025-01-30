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

      if (currProgress == null && apiUser == null) return;

      if (currProgress == null && apiUser != null) {
        await SharedPref.setCurrProgress(apiUser.level, apiUser.subLevel);
        return;
      } else if (currProgress != null && apiUser == null) {
        await userController.progressSync(currProgress['level'], currProgress['subLevel']);
        return;
      }

      final localLastModified = DateTime.fromMillisecondsSinceEpoch(currProgress!['modified'] ?? 0);
      final apiLastModified = DateTime.parse(apiUser!.modified);

      if (localLastModified.isAfter(apiLastModified)) {
      } else {
        await SharedPref.setCurrProgress(apiUser.level, apiUser.subLevel);
      }
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
