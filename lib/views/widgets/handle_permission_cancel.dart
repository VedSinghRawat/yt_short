import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> handlePermissionDenied(BuildContext context, String errorMessage, {required Permission permission}) async {
  try {
    PermissionStatus permissionStatus = await permission.request();

    if (permissionStatus == PermissionStatus.granted) return;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: Text(errorMessage),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  } catch (e) {
    developer.log('error in handlePermissionDenied $e');
  }
}
