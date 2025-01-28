import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/features/activity_log/activity_log.controller.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
import 'package:myapp/models/content/content.dart';
import '../../features/content/content_controller.dart';
import '../../features/content/widget/content_list.dart';
import '../widgets/custom_app_bar.dart';
import '../../features/user/user_controller.dart';
import '../../features/auth/auth_controller.dart';
import 'dart:developer' as developer;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Content> _contents = [];
  int? _jumpTo;

  @override
  void initState() {
    super.initState();
    // Fetch videos when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(contentControllerProvider.notifier).fetchContents();
      final progress = await SharedPref.getCurrProgress();
      _contents = ref
          .read(contentControllerProvider)
          .contentKeysByLevel[progress?['level'] ?? 1]!
          .map((key) => ref.read(contentControllerProvider).contentMap[key]!)
          .toList();

      _jumpTo = _contents.indexWhere(
        (content) =>
            content.speechExercise?.subLevel == progress?['subLevel'] && content.speechExercise?.level == progress?['level'] ||
            content.video?.subLevel == progress?['subLevel'] && content.video?.level == progress?['level'],
      );
      developer.log('jumpTo: $_jumpTo');
    });
  }

  Future<void> _handleOnScroll(int index) async {
    final userEmail = ref.read(userControllerProvider).currentUser?.email ?? '';
    if (index < 0 || index >= _contents.length) return;

    final content = _contents[index];
    final level = (content.speechExercise?.level ?? content.video?.level)!;
    final subLevel = (content.speechExercise?.subLevel ?? content.video?.subLevel)!;

    await SharedPref.setCurrProgress(level, subLevel);

    if (subLevel > kAuthRequiredLevel && userEmail.isEmpty && mounted) {
      context.go(Routes.signIn);
    }

    await SharedPref.setCurrProgress(level, subLevel);

    if (userEmail.isNotEmpty) {
      await SharedPref.addActivityLog(ActivityLog(subLevel: subLevel, level: level, userEmail: userEmail, created: DateTime.now()));
    }

    const minDiff = Duration.millisecondsPerMinute * 10;
    final lastSync = await SharedPref.getLastSync();

    final now = DateTime.now().millisecondsSinceEpoch;

    if ((now - lastSync) < minDiff) return;

    if (userEmail.isNotEmpty) {
      await ref.read(userControllerProvider.notifier).progressSync(level, subLevel);
    }

    final activityLogs = await SharedPref.getActivityLogs();
    if (activityLogs == null || activityLogs.isEmpty) return;
    await ref.read(activityLogControllerProvider.notifier).syncActivityLogs(activityLogs);
    await SharedPref.clearActivityLogs();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('HomeScreen build: $_jumpTo');

    if (ref.read(contentControllerProvider).loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_contents.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No videos available'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Learn English',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'signout') {
                ref.read(authControllerProvider.notifier).signOut(context);
                context.go(Routes.signIn);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ContentsList(
        contents: _contents,
        onVideoChange: _handleOnScroll,
        jumpTo: _jumpTo,
      ),
    );
  }
}
