import 'package:flutter/material.dart';
import 'package:myapp/views/widgets/lang_text.dart';

class ErrorPage extends StatelessWidget {
  final VoidCallback? onButtonClick;
  final String text;
  final String? buttonText;

  const ErrorPage({super.key, this.onButtonClick, required this.text, this.buttonText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LangText.bodyText(
            text: text,
            overflow: TextOverflow.clip,
            style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (buttonText != null) ElevatedButton(onPressed: onButtonClick, child: LangText.bodyText(text: buttonText!)),
        ],
      ),
    );
  }
}
