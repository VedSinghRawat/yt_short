import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showErrorSnackBar(BuildContext context, String message) {
  // Remove mounted check since ScaffoldMessenger handles this internally
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
    ),
  );
}

void showSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
