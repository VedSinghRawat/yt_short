import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/services/initialize_service.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');

  await initializeApp();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> initializeApp() async {
  final container = ProviderContainer();

  await container.read(initializeServiceProvider.future);

  container.dispose();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'English Course',
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: router,
    );
  }
}
