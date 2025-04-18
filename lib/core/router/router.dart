import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/screen/deep_linking.dart';
import 'package:myapp/core/services/initialize_service.dart';
import 'package:myapp/core/widgets/version_check_wrapper.dart';
import 'package:myapp/features/auth/screens/sign_in_screen.dart';
import 'package:myapp/core/screen/home.dart';
import 'package:myapp/core/screen/suggest_version_update.dart';
import 'package:myapp/core/screen/require_version_update.dart';
import 'package:myapp/features/auth/widgets/auth_wrapper.dart';
import 'package:myapp/features/initialize/initialize_screen.dart';
import 'package:myapp/core/screen/profile.dart';

class Routes {
  static const home = '/home';
  static const versionRequired = '/version/required';
  static const versionSuggest = '/version/suggest';
  static const signIn = '/signIn';
  static const deepLinking = '/deepLinking';
  static const initializeScreen = '/';
  static const profile = '/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: Routes.initializeScreen,
    routes: [
      // Version check routes - not wrapped with VersionCheckWrapper to avoid loops
      GoRoute(
        path: Routes.versionSuggest,
        builder: (context, state) => const SuggestVersionUpdate(),
      ),
      GoRoute(
        path: Routes.versionRequired,
        builder: (context, state) => const RequireVersionUpdate(),
      ),
      // Main app routes - wrapped with VersionCheckWrapper
      GoRoute(
        path: Routes.home,
        builder:
            (context, state) => const AuthWrapper(child: VersionCheckWrapper(child: HomeScreen())),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const VersionCheckWrapper(child: SignInScreen()),
      ),
      GoRoute(path: Routes.deepLinking, builder: (context, state) => const DeepLinkingScreen()),

      GoRoute(path: Routes.initializeScreen, builder: (context, state) => const InitializeScreen()),

      GoRoute(path: Routes.profile, builder: (context, state) => const ProfileScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
});
