import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  final VoidCallback onRefresh;
  final String text;
  final String buttonText;

  const ErrorPage({
    super.key,
    required this.onRefresh,
    required this.text,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRefresh,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
