import 'package:flutter/material.dart';
import 'package:myapp/views/widgets/lang_text.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String question,
  ButtonStyle? yesButtonStyle,
  ButtonStyle? noButtonStyle,
}) async {
  bool result = false;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const LangText.headingText(text: 'Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        content: LangText.bodyText(text: question, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              result = false;
            },
            style: noButtonStyle ?? TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const LangText.bodyText(text: 'No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              result = true;
            },
            style:
                yesButtonStyle ??
                ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
            child: const LangText.bodyText(text: 'Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );

  return result;
}
