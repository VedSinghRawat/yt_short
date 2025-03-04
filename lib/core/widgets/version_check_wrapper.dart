import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/apis/version_api.dart';
import 'package:myapp/core/controllers/version_controller.dart';
import 'package:myapp/core/router/router.dart';
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

final Map<VersionType, String> routeToVersionType = {
  VersionType.required: Routes.versionRequired,
  VersionType.suggested: Routes.versionSuggest,
};

class _VersionCheckWrapperState extends ConsumerState<VersionCheckWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final versionType = await ref.read(versionControllerProvider.notifier).checkVersion(context);
      final route = routeToVersionType[versionType];

      if (route != null && mounted) {
        context.go(route);
      }

      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Loader();
    }

    return widget.child;
  }
}
