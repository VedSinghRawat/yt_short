import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/router/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: kDebugMode ? '.env' : '.env.prod');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final customDarkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color.fromARGB(255, 223, 150, 39), // Slightly lighter surfaces
        onPrimary: Colors.white70,
        secondary: Color.fromARGB(255, 10, 59, 117),
        onSecondary: Colors.white70, // Text/icons on secondary color
        error: Colors.redAccent,
        onError: Colors.black, // Text/icons on error color
        surface: Color.fromARGB(255, 20, 20, 20),
        onSurface: Color.fromARGB(255, 250, 248, 248), // Text/icons on surfaces
      ),
      useMaterial3: true,
    );

    return MaterialApp.router(
      title: 'English Course',
      theme: customDarkTheme, // Use the custom theme
      routerConfig: router,
    );
  }
}
