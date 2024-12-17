import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/widgets/yt_shorts_list.dart';
import 'package:myapp/core/supabase/supabase_config.dart';
import 'package:myapp/features/auth/presentation/widgets/auth_wrapper.dart';
import 'package:myapp/features/auth/presentation/providers/auth_provider.dart';

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

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider).signOut();
            },
          ),
        ],
      ),
      body: const Center(
        child: YoutubeShortsList(videoIds: shortIds),
      ),
    );
  }
}
