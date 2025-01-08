import 'package:flutter/material.dart';
import 'package:speech_reco/speech_screen.dart';

class InputScreen extends StatelessWidget {
  const InputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Text'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter some text here...',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the second screen with the entered text
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SpeechScreen(text: textController.text),
                  ),
                );
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
