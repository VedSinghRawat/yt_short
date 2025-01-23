import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/widgets/version_check_wrapper.dart';
import 'package:myapp/features/auth/screens/sign_in_screen.dart';
import 'package:myapp/core/screen/home.dart';
import 'package:myapp/core/screen/suggest_version_update.dart';
import 'package:myapp/core/screen/require_version_update.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/signIn',
    routes: [
      // Version check routes - not wrapped with VersionCheckWrapper to avoid loops
      GoRoute(
        path: '/version/suggest',
        builder: (context, state) => const SuggestVersionUpdate(),
      ),
      GoRoute(
        path: '/version/required',
        builder: (context, state) => const RequireVersionUpdate(),
      ),
      // Main app routes - wrapped with VersionCheckWrapper
      GoRoute(
        path: '/',
        builder: (context, state) => const VersionCheckWrapper(
          child: HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/signIn',
        builder: (context, state) => const VersionCheckWrapper(
          child: SignInScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
});
