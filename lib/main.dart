import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/services/initialize_service.dart';
import 'package:myapp/core/widgets/loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final app = MaterialApp.router(
      title: 'English Course',
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: router,
    );

    return ref.watch(initializeServiceProvider).when(
      data: (data) {
        return app;
      },
      error: (error, stackTrace) {
        return app;
      },
      loading: () {
        return const MaterialApp(home: Scaffold(body: Loader()));
      },
    );
  }
}
