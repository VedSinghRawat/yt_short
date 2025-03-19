import 'package:flutter/material.dart';

class LastLevelWidget extends StatelessWidget {
  final VoidCallback onRefresh;

  const LastLevelWidget({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'These are all the lessons for now, Check in after sometime for new content',
            style: TextStyle(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Reload Videos!'),
          ),
        ],
      ),
    );
  }
}
