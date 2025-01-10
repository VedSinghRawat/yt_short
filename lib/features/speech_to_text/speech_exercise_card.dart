import 'package:flutter/material.dart';
import 'package:myapp/features/speech_to_text/recognizer.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechExerciseCard extends StatefulWidget {
  final String text;

  const SpeechExerciseCard({super.key, required this.text});

  @override
  State<SpeechExerciseCard> createState() => _SpeechExerciseCardState();
}

class _SpeechExerciseCardState extends State<SpeechExerciseCard> {
  late List<String> words;
  late List<bool?> wordMarking;
  int lastMatchedIndex = -1;
  late SpeechRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    words = widget.text.split(' ');
    wordMarking = List.generate(words.length, (index) => null);
    _recognizer = SpeechRecognizer(
      onResult: _onSpeechResult,
      onStopListenting: _onStopListening,
    );
  }

  void _onStopListening() {
    setState(() {
      lastMatchedIndex = -1;
      wordMarking = List.generate(words.length, (index) => null);
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    List<String> recognizedWords = result.recognizedWords.split(' ').where((word) => word.isNotEmpty).toList();
    if (recognizedWords.isEmpty) return;

    int nextIndexToHighlight = lastMatchedIndex + 1;
    if (!(nextIndexToHighlight < words.length)) return;

    String lastRecognizedWord = recognizedWords.last.toLowerCase();
    String targetWord = words[nextIndexToHighlight].toLowerCase();

    setState(() {
      wordMarking[nextIndexToHighlight] = targetWord == lastRecognizedWord;
      lastMatchedIndex += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speak'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.symmetric(vertical: 24.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: List.generate(words.length, (index) {
                            return WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Text(
                                    '${words[index]} ',
                                    style: TextStyle(
                                      color: wordMarking[index] == null
                                          ? Colors.black87
                                          : wordMarking[index] == true
                                              ? Colors.lightBlue[200]
                                              : Colors.red,
                                      fontSize: 24,
                                      fontWeight: wordMarking[index] != null ? FontWeight.bold : FontWeight.normal,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: List.generate(words.length, (index) {
                            return WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Text(
                                    '${words[index]} ',
                                    style: TextStyle(
                                      color: wordMarking[index] == null
                                          ? Colors.black87
                                          : wordMarking[index] == true
                                              ? Colors.lightBlue[200]
                                              : Colors.red,
                                      fontSize: 24,
                                      fontWeight: wordMarking[index] != null ? FontWeight.bold : FontWeight.normal,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                )),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _recognizer.isListening ? Colors.green.shade100 : Colors.blue.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (_recognizer.isListening) {
                          _recognizer.stopListening();
                        } else {
                          _recognizer.startListening();
                        }
                      });
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _recognizer.isListening ? Icons.mic : Icons.mic_none,
                        color: _recognizer.isListening ? Colors.green : Colors.blue,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
