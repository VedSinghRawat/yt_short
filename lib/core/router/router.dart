import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/auth/screens/sign_in_screen.dart';
import 'package:myapp/features/auth/screens/sign_up_screen.dart';
import 'package:myapp/features/videos/screen/video_list.dart';
import 'package:myapp/features/auth/widgets/auth_wrapper.dart';
import 'package:myapp/features/auth/auth_controller.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      // If we're not on an auth route and not authenticated, redirect to signin
      if (authState.authState == AuthState.unauthenticated && !isAuthRoute) {
        return '/auth/signin';
      }

      // If we're authenticated and on an auth route, redirect to home
      if (authState.authState == AuthState.authenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthWrapper(
          child: VideoListScreen(),
        ),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const SignInScreen(),
        routes: [
          GoRoute(
            path: 'signin',
            builder: (context, state) => const SignInScreen(),
          ),
          GoRoute(
            path: 'signup',
            builder: (context, state) => const SignUpScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
});
