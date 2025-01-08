import 'package:flutter/material.dart';
import 'package:myapp/features/speech_to_text/recognizer.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechScreen extends StatefulWidget {
  final String text;

  const SpeechScreen({super.key, required this.text});

  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  late List<String> words; 
  late List<bool> highlightWords;
  int lastMatchedIndex = -1; 

  @override
  void initState() {
    super.initState();
    words = widget.text.split(' ');
    highlightWords = List.generate(words.length, (index) => false); // No words are highlighted initially
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    List<String> recognizedWords = result.recognizedWords.split(' ');
    if (recognizedWords.isNotEmpty) {
      String lastRecognizedWord = recognizedWords.last.toLowerCase();

      int nextIndexToHighlight = lastMatchedIndex + 1;

      if (nextIndexToHighlight < words.length) {
        String targetWord = words[nextIndexToHighlight].toLowerCase();

        int minLength = targetWord.length < lastRecognizedWord.length ? targetWord.length : lastRecognizedWord.length;
        int matchCount = 0;

        for (int i = 0; i < minLength; i++) {
          if (targetWord[i] == lastRecognizedWord[i]) {
            matchCount++;
          }
        }

        double similarity = matchCount / minLength;

        if (targetWord == lastRecognizedWord || similarity >= 0.6) {
          setState(() {
            highlightWords[nextIndexToHighlight] = true;
            lastMatchedIndex = nextIndexToHighlight;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speak'),
      ),
      body: Column(
        children: [
          // Display the original text with highlighted words
          Text.rich(
            TextSpan(
              children: List.generate(words.length, (index) {
                return TextSpan(
                  text: '${words[index]} ',
                  style: TextStyle(
                    color: highlightWords[index] ? Colors.blue : Colors.black,
                    fontSize: 20,
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
          SpeechRecognition(onChange: _onSpeechResult),
        ],
      ),
    );
  }
}
