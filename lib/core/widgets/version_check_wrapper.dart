import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(versionControllerProvider.notifier).checkVersion(context);

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

    final state = ref.watch(versionControllerProvider);
    final content = state.content;
    final closable = state.closable;

    if (content == null) {
      return widget.child;
    }

    return Scaffold(
      appBar: closable
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(versionControllerProvider.notifier).dismissMessage();
                  },
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Center(
          child: HtmlWidget(
            content,
            onTapUrl: (url) {
              final prov = ref.read(versionControllerProvider.notifier);
              url == 'closeAction' ? prov.dismissMessage() : prov.openStore(context);
              return true;
            },
          ),
        ),
      ),
    );
  }
}
