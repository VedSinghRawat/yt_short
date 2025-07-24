import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/views/screens/deep_linking_screen.dart';
import 'package:myapp/services/initialize/initialize_service.dart';
import 'package:myapp/views/screens/home_screen.dart';
import 'package:myapp/views/widgets/auth/auth_wrapper.dart';
import 'package:myapp/views/widgets/obstructive_error_wrapper.dart';
import 'package:myapp/views/screens/sign_in_screen.dart';
import 'package:myapp/views/screens/initialize_screen.dart';
import 'package:myapp/views/screens/profile_screen.dart';
import 'package:myapp/views/widgets/lang_text.dart';

class Routes {
  static const home = '/home';
  static const signIn = '/signIn';
  static const deepLinking = '/deepLinking';
  static const init = '/';
  static const profile = '/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: Routes.init,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return ObstructiveErrorWrapper(child: child);
        },

        routes: [
          GoRoute(path: Routes.home, builder: (context, state) => const AuthWrapper(child: HomeScreen())),

          GoRoute(path: Routes.signIn, builder: (context, state) => const SignInScreen()),

          GoRoute(path: Routes.deepLinking, builder: (context, state) => const DeepLinkingScreen()),

          GoRoute(path: Routes.init, builder: (context, state) => const InitializeScreen()),

          GoRoute(path: Routes.profile, builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: LangText.bodyText(text: 'Error: ${state.error}'))),
  );
});
