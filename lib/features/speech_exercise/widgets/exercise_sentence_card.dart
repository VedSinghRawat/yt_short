import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/active_mic.dart';
import 'package:myapp/features/speech_exercise/widgets/recognizer.dart';
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
  late List<String> words;
  late List<bool?> wordMarking;
  int offset = 0;
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
      wordMarking = List.generate(words.length, (index) => null);
      recognizedWords = List.filled(words.length, '');
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      List<String> currRecognizedWords = result.recognizedWords.split(' ').where((word) => word.isNotEmpty).toList();
      if (currRecognizedWords.isEmpty) {
        offset = recognizedWords.where((word) => word.isNotEmpty).length;
        return;
      }

      for (var i = 0; i < currRecognizedWords.length; i++) {
        recognizedWords[i + offset] = currRecognizedWords[i];
      }

      for (int i = 0; i < recognizedWords.where((word) => word.isNotEmpty).length; i++) {
        String targetWord = words[i].toLowerCase();
        String lowerRecognizedWord = recognizedWords[i].toLowerCase();

        wordMarking[i] = targetWord == lowerRecognizedWord;
      }
    });
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
                        for (int i = 0; i < words.length; i++)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Recognized word
                              recognizedWords[i].isNotEmpty
                                  ? Text(
                                      recognizedWords[i],
                                      style: recognizedWordStyle.copyWith(
                                        textBaseline: TextBaseline.alphabetic,
                                      ),
                                    )
                                  : const SizedBox(height: recognizedWordHeight),

                              // Target word
                              Text(
                                words[i],
                                style: TextStyle(
                                  color: wordMarking[i] == null
                                      ? Colors.white60
                                      : wordMarking[i] == true
                                          ? Colors.lightBlue[200]
                                          : wordMarking[i] == false
                                              ? Colors.red
                                              : Colors.white,
                                  fontSize: 24,
                                  fontWeight: wordMarking[i] != null ? FontWeight.bold : FontWeight.normal,
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
                  onTap: () async {
                    if (passed) {
                      widget.onContinue();
                      _recognizer.stopListening();
                    } else {
                      if (_recognizer.isListening) {
                        _recognizer.stopListening();
                      } else {
                        await _recognizer.startListening();
                      }
                      setState(() {
                        _recognizer = _recognizer;
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
                              passed ? 'Continue' : 'Retry',
                              style: TextStyle(
                                color: passed ? Colors.green.shade700 : Colors.red.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : _recognizer.isListening
                              ? const ActiveMic()
                              : const Icon(
                                  Icons.mic_none,
                                  color: Colors.blue,
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
