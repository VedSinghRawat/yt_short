import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/widgets/yt_shorts_list.dart';
import 'package:myapp/core/supabase/supabase_config.dart';
import 'package:myapp/features/auth/widgets/auth_wrapper.dart';
import 'package:myapp/features/auth/auth_controller.dart';
import 'package:myapp/features/videos/video_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Youtube Shorts',
      theme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: const AuthWrapper(
        child: MyHomePage(title: 'Youtube Shorts'),
      ),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Fetch videos when the page loads
    Future.microtask(() => ref.read(videoControllerProvider.notifier).fetchVideos());
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoControllerProvider);
    final authController = ref.watch(authControllerProvider.notifier);

    Widget buildBody() {
      switch (videoState.state) {
        case VideoState.error:
          developer.log('video api err:', error: videoState.errorMessage);
          return Center(child: Text('Error: ${videoState.errorMessage}'));
        case VideoState.loaded:
          final videoIds = videoState.videos.map((video) => video.id).toList();
          return YoutubeShortsList(videoIds: videoIds);
        case VideoState.initial:
        case VideoState.loading:
          return const Center(child: CircularProgressIndicator());
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authController.signOut();
            },
          ),
        ],
      ),
      body: buildBody(),
    );
  }
}
