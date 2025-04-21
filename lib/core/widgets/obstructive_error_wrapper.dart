import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/controllers/ObstructiveError/obstructive_error_controller.dart';

class ObstructiveErrorWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final Function(String url)? onTapUrl;

  const ObstructiveErrorWrapper({super.key, required this.child, this.onTapUrl});

  @override
  ConsumerState<ObstructiveErrorWrapper> createState() => _ObstructiveErrorWrapperState();
}

class _ObstructiveErrorWrapperState extends ConsumerState<ObstructiveErrorWrapper> {
  @override
  void initState() {
    super.initState();
  }

  Future<bool> _handleOnTapUrl(String url) async {
    if (url == AppConstants.kViewCloseActionName) {
      ref.read(obstructiveErrorControllerProvider.notifier).dismissObstructiveError();
    } else if (widget.onTapUrl != null) {
      await widget.onTapUrl!(url);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final obstructiveError = ref.watch(obstructiveErrorControllerProvider);
    final dismiss = ref.read(obstructiveErrorControllerProvider.notifier).dismissObstructiveError;
    final content = obstructiveError.content;
    final closable = obstructiveError.closable;

    if (content == null) {
      return widget.child;
    }

    return Scaffold(
      appBar:
          closable
              ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [IconButton(icon: const Icon(Icons.close), onPressed: dismiss)],
              )
              : null,
      body: SafeArea(child: Center(child: HtmlWidget(content, onTapUrl: _handleOnTapUrl))),
    );
  }
}
