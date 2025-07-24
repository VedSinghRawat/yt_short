import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:myapp/views/widgets/lang_text.dart';

Future<void> handlePermissionDenied(BuildContext context, String errorMessage, {required Permission permission}) async {
  try {
    PermissionStatus permissionStatus = await permission.request();

    if (permissionStatus == PermissionStatus.granted) return;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const LangText.headingText(text: 'Permission Required'),
            content: LangText.bodyText(text: errorMessage),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const LangText.bodyText(text: 'Cancel')),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const LangText.bodyText(text: 'Open Settings'),
              ),
            ],
          ),
    );
  } catch (e) {
    developer.log('error in handlePermissionDenied $e');
  }
}
