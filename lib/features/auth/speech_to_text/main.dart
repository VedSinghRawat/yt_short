import 'package:flutter/material.dart';
import 'package:speech_reco/input_screen.dart';

void main() {
  runApp(const SpeechRecognitionApp());
}

class SpeechRecognitionApp extends StatelessWidget {
  const SpeechRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InputScreen(),
    );
  }
}
