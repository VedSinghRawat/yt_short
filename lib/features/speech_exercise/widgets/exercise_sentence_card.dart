import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:myapp/features/speech_exercise/widgets/recognizer_button.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class ExerciseSentenceCard extends StatefulWidget {
  final String text;
  final VoidCallback onContinue;

  const ExerciseSentenceCard({
    super.key,
    required this.text,
    required this.onContinue,
  });

  @override
  State<ExerciseSentenceCard> createState() => _ExerciseSentenceCardState();
}

class _ExerciseSentenceCardState extends State<ExerciseSentenceCard> {
  late List<String> _words;
  late List<bool?> _wordMarking;
  int _offset = 0;
  late List<String> _recognizedWords;
  bool get passed => _wordMarking.every((mark) => mark == true);
  bool get failed =>
      _recognizedWords.where((word) => word.isNotEmpty).toList().length == _words.length && !passed;
  bool get testCompleted => passed || failed;

  @override
  void initState() {
    super.initState();
    _words = widget.text.split(' ');
    _wordMarking = List.generate(_words.length, (index) => null);
    _recognizedWords = List.filled(_words.length, '');
  }

  void _onStopListening() {
    setState(() {
      _wordMarking = List.generate(_words.length, (index) => null);
      _recognizedWords = List.filled(_words.length, '');
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    List<String> currRecognizedWords =
        result.recognizedWords.split(' ').where((word) => word.isNotEmpty).toList();

    setState(() {
      if (currRecognizedWords.isEmpty) {
        _offset = _recognizedWords.where((word) => word.isNotEmpty).length;
        return;
      }

      for (var i = 0; i < currRecognizedWords.length; i++) {
        _recognizedWords[i + _offset] = currRecognizedWords[i];
      }

      for (int i = 0; i < _recognizedWords.where((word) => word.isNotEmpty).length; i++) {
        String formatedTargetWord = formatWord(_words[i]);
        String formatedRecognizedWord = formatWord(_recognizedWords[i]);

        _wordMarking[i] = formatedTargetWord == formatedRecognizedWord;
      }
    });
  }

  String formatWord(String word) {
    return word.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    // Match font sizes and line heights to keep total vertical space in sync
    const double recognizedWordFontSize = 24;
    const double recognizedWordLineHeight = 1.4; // Adjust if needed

    final recognizedWordStyle = TextStyle(
      color: Colors.grey[400],
      fontSize: recognizedWordFontSize,
      fontWeight: FontWeight.w300,
      height: recognizedWordLineHeight,
    );

    const recognizedWordHeight = recognizedWordFontSize * recognizedWordLineHeight;

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
                    Wrap(
                      spacing: 8, // horizontal spacing between items
                      runSpacing: 16, // vertical spacing between lines
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (int i = 0; i < _words.length; i++)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Recognized word
                              _recognizedWords[i].isNotEmpty
                                  ? Text(
                                      _recognizedWords[i],
                                      style: recognizedWordStyle.copyWith(
                                        textBaseline: TextBaseline.alphabetic,
                                      ),
                                    )
                                  : const SizedBox(height: recognizedWordHeight),

                              // Target word
                              Text(
                                _words[i],
                                style: TextStyle(
                                  color: _wordMarking[i] == null
                                      ? Colors.white60
                                      : _wordMarking[i] == true
                                          ? Colors.lightBlue[200]
                                          : _wordMarking[i] == false
                                              ? Colors.red
                                              : Colors.white,
                                  fontSize: 24,
                                  fontWeight:
                                      _wordMarking[i] != null ? FontWeight.bold : FontWeight.normal,
                                  height: 1.4,
                                  textBaseline: TextBaseline.alphabetic,
                                ),
                              ),
                            ],
                          ),
                      ],
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
            child: RecognizerButton(
              testCompleted: testCompleted,
              passed: passed,
              failed: failed,
              onContinue: widget.onContinue,
              onResult: _onSpeechResult,
              onStopListening: _onStopListening,
            ),
          ),
        ],
      ),
    );
  }
}
