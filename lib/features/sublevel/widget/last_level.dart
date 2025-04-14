import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  final VoidCallback? onRefresh;
  final String text;
  final String? buttonText;

  const ErrorPage({
    super.key,
    this.onRefresh,
    required this.text,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            overflow: TextOverflow.clip,
            style: const TextStyle(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (buttonText != null)
            ElevatedButton(onPressed: onRefresh, child: Text(buttonText!)),
        ],
      ),
    );
  }
}
