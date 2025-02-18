import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/controllers/version_controller.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/widgets/loader.dart';

class VersionCheckWrapper extends ConsumerWidget {
  final Widget child;

  const VersionCheckWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(versionControllerProvider.notifier).checkVersion(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Loader();
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Use go_router to navigate to the appropriate route
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (snapshot.data != Routes.home) {
              context.go(snapshot.data!);
            }
          });
        }

        return child;
      },
    );
  }
}
