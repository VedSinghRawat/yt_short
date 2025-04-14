import 'package:flutter/material.dart';

Future<void> showConfirmationDialog(
  BuildContext context, {
  required String question,
  required ValueChanged<bool> onResult,
  ButtonStyle? yesButtonStyle,
  ButtonStyle? noButtonStyle,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Text(question, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onResult(false);
            },
            style:
                noButtonStyle ??
                TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onResult(true);
            },
            style:
                yesButtonStyle ??
                ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}
