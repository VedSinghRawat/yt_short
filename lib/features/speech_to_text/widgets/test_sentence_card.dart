import 'package:flutter/material.dart';
import 'package:myapp/features/speech_to_text/widgets/recognizer.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class TestSentenceCard extends StatefulWidget {
  final String text;
  final VoidCallback onContinue;

  const TestSentenceCard({
    super.key,
    required this.text,
    required this.onContinue,
  });

  @override
  State<TestSentenceCard> createState() => _TestSentenceCardState();
}

class _TestSentenceCardState extends State<TestSentenceCard> {
  late List<String> words;
  late List<bool?> wordMarking;
  int currIndex = -1;
  late SpeechRecognizer _recognizer;
  late List<String> recognizedWords;
  bool get passed => wordMarking.every((mark) => mark == true);
  bool get failed => recognizedWords.where((word) => word.isNotEmpty).toList().length == words.length && !passed;
  bool get testCompleted => passed || failed;

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
    if (wordsList.isEmpty) return;

    setState(() {
      for (int i = currIndex + 1; i < wordsList.length; i++) {
        String lowerRecognizedWord = wordsList[i].toLowerCase();
        String targetWord = words[i].toLowerCase();

        wordMarking[i] = targetWord == lowerRecognizedWord;
        recognizedWords[i] = lowerRecognizedWord;
        currIndex = i;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 24.0),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        "Please speak the sentence given below to continue",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: List.generate(words.length, (index) {
                            return WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0), // Adjust horizontal padding as needed
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Always reserve space for recognizedWord
                                    wordMarking[index] == false && recognizedWords[index].isNotEmpty
                                        ? Text(
                                            recognizedWords[index],
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 18,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          )
                                        : const SizedBox(
                                            height: 28, // Same height as the recognizedWord Text
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
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    if (testCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: passed ? Colors.green[300] : Colors.red[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            passed ? Icons.check : Icons.close,
                            color: Colors.white,
                            size: 32, // Adjust icon size as needed
                          ),
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
              width: testCompleted ? 160 : 80,
              height: testCompleted ? 60 : 80,
              decoration: BoxDecoration(
                shape: testCompleted ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: testCompleted ? BorderRadius.circular(40) : null,
                color: failed
                    ? Colors.red.shade100
                    : _recognizer.isListening | passed
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
                    if (passed) {
                      widget.onContinue();
                    } else {
                      setState(() {
                        if (_recognizer.isListening) {
                          _recognizer.stopListening();
                        } else {
                          _recognizer.startListening();
                        }
                      });
                    }
                  },
                  customBorder: passed ? null : const CircleBorder(),
                  child: Container(
                    width: passed ? 160 : 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: passed ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: passed ? BorderRadius.circular(40) : null,
                    ),
                    child: Center(
                      child: testCompleted
                          ? Text(
                              passed ? 'Continue' : 'Reset',
                              style: TextStyle(
                                color: passed ? Colors.green.shade700 : Colors.red.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Icon(
                              _recognizer.isListening ? Icons.mic : Icons.mic_none,
                              color: _recognizer.isListening ? Colors.green : Colors.blue,
                              size: 32,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
