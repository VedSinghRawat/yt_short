import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/controllers/version_controller.dart';
import 'package:myapp/core/widgets/loader.dart';

class VersionCheckWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const VersionCheckWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends ConsumerState<VersionCheckWrapper> {
  String? route;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    ref.read(versionControllerProvider.notifier).checkVersion(context).then((value) {
      setState(() {
        route = value;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(route!);
      });
    }

    if (route == null) {
      return widget.child;
    }

    return const Loader();
  }
}
