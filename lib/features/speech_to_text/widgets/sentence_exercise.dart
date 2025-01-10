import 'package:flutter/material.dart';
import 'package:myapp/features/speech_to_text/widgets/recognizer.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeakSentenceExercise extends StatefulWidget {
  final String text;

  const SpeakSentenceExercise({super.key, required this.text});

  @override
  State<SpeakSentenceExercise> createState() => _SpeakSentenceExerciseState();
}

class _SpeakSentenceExerciseState extends State<SpeakSentenceExercise> {
  late List<String> words;
  late List<bool?> wordMarking;
  int currIndex = -1;
  late SpeechRecognizer _recognizer;
  late List<String> recognizedWords;
  bool get allWordsCorrect => wordMarking.every((mark) => mark == true);

  @override
  void initState() {
    super.initState();
    words = widget.text.split(' ');
    wordMarking = List.generate(words.length, (index) => null);
    recognizedWords = List.filled(words.length, '');
    _recognizer = SpeechRecognizer(
      onResult: _onSpeechResult,
      onStopListenting: _onStopListening,
    );
  }

  void _onStopListening() {
    setState(() {
      currIndex = -1;
      wordMarking = List.generate(words.length, (index) => null);
      recognizedWords = List.filled(words.length, '');
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    List<String> wordsList = result.recognizedWords.split(' ').where((word) => word.isNotEmpty).toList();
    print('Processing final result: $wordsList');
    if (wordsList.isEmpty) return;

    setState(() {
      for (int i = currIndex + 1; i < wordsList.length; i++) {
        String lowerRecognizedWord = wordsList[i].toLowerCase();
        String targetWord = words[i].toLowerCase();
        print('Processing - Index: $i, Recognized: $lowerRecognizedWord, Target: $targetWord');

        wordMarking[i] = targetWord == lowerRecognizedWord;
        recognizedWords[i] = lowerRecognizedWord;
        currIndex = i;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speak the sentence given below.'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24.0),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Column(
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
                                    if (wordMarking[index] == false)
                                      Positioned(
                                        top: -25,
                                        child: Text(
                                          recognizedWords[index],
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 18,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      '${words[index]} ',
                                      style: TextStyle(
                                        color: wordMarking[index] == null
                                            ? Colors.white70
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
                      if (allWordsCorrect)
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green[300],
                            size: 48,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: allWordsCorrect
                      ? Colors.yellow.shade100
                      : _recognizer.isListening
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
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
                        allWordsCorrect
                            ? Icons.close_fullscreen
                            : _recognizer.isListening
                                ? Icons.mic
                                : Icons.mic_none,
                        color: allWordsCorrect
                            ? Colors.yellow.shade700
                            : _recognizer.isListening
                                ? Colors.green
                                : Colors.blue,
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
