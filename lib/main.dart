import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/services/initialize_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    // handleDeepLinking();
  }

  // Future<void> handleDeepLinking() async {
  //   final appLinks = AppLinks();

  //   appLinks.uriLinkStream.listen((uri) async {
  //     final pathSegments = uri.pathSegments;
  //     if (pathSegments.length >= 2 && pathSegments[0] == 'cyid') {
  //       final cyId = pathSegments[1];
  //       await SharedPref.setCyId(cyId);

  //       developer.log('cyid $cyId');

  //       if (!mounted) return;

  //       context.pushNamed(Routes.deepLinking);
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
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
