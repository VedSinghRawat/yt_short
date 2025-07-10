import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/views/screens/deep_linking.dart';
import 'package:myapp/services/initialize/initialize_service.dart';
import 'package:myapp/views/widgets/obstructive_error_wrapper.dart';
import 'package:myapp/views/screens/sign_in_screen.dart';
import 'package:myapp/views/screens/initialize_screen.dart';
import 'package:myapp/views/screens/profile.dart';
import 'package:myapp/views/screens/arrange_exercise_screen.dart';
import 'package:myapp/models/arrange_exercise/arrange_exercise.dart';

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
          // Original home route commented out for testing
          // GoRoute(path: Routes.home, builder: (context, state) => const AuthWrapper(child: HomeScreen())),

          // Home route now points to arrange exercise screen for testing
          GoRoute(
            path: Routes.home,
            builder:
                (context, state) => ArrangeExerciseScreen(
                  exercise: const ArrangeExercise(
                    id: 'mock_exercise_1',
                    text: 'The man is on the phone',
                    level: 1,
                    index: 1,
                    levelId: 'level_1',
                  ),
                  goToNext: () {
                    // Mock next action - could navigate to another screen or show success
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Great! Exercise completed!'), backgroundColor: Colors.green),
                    );
                  },
                ),
          ),

          GoRoute(path: Routes.signIn, builder: (context, state) => const SignInScreen()),

          GoRoute(path: Routes.deepLinking, builder: (context, state) => const DeepLinkingScreen()),

          GoRoute(path: Routes.init, builder: (context, state) => const InitializeScreen()),

          GoRoute(path: Routes.profile, builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
});
