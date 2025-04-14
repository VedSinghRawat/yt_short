import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool ignoreInteractions; // new prop

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.ignoreInteractions = false, // default false
  });

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      elevation: 0,
      actions: actions,
    );

    return ignoreInteractions ? IgnorePointer(child: appBar) : appBar;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
