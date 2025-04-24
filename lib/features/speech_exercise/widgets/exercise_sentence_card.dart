import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
import 'package:myapp/features/speech_exercise/widgets/recognizer_button.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechExerciseCard extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback onContinue;

  const SpeechExerciseCard({super.key, required this.text, required this.onContinue});

  @override
  ConsumerState<SpeechExerciseCard> createState() => _SpeechExerciseCardState();
}

class _SpeechExerciseCardState extends ConsumerState<SpeechExerciseCard> {
  late List<List<String>> _words;
  late List<bool?> _wordMarking;
  int _offset = 0;
  late List<String> _recognizedWords;
  late int _totalWordCount;

  bool get passed => _wordMarking.every((mark) => mark == true);
  bool get failed =>
      _recognizedWords.where((word) => word.isNotEmpty).toList().length == _totalWordCount &&
      !passed;
  bool get testCompleted => passed || failed;

  @override
  void initState() {
    super.initState();
    _words = [];
    _totalWordCount = 0;

    // Split text by new lines to maintain line structure
    final lines = widget.text.split('\n');
    for (var line in lines) {
      List<String> lineWords = [];
      for (var word in line.split(' ')) {
        word = word.trim();
        if (word.isNotEmpty) {
          lineWords.add(word);
          _totalWordCount++;
        }
      }
      if (lineWords.isNotEmpty) {
        _words.add(lineWords);
      }
    }

    _wordMarking = List.generate(_totalWordCount, (index) => null);
    _recognizedWords = List.filled(_totalWordCount, '');
  }

  void _onStopListening() {
    if (!context.mounted) return;

    setState(() {
      _wordMarking = List.generate(_totalWordCount, (index) => null);
      _recognizedWords = List.filled(_totalWordCount, '');
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
        // Get the actual word from the nested structure
        String targetWord = _getWordAtIndex(i);
        String formatedTargetWord = formatWord(targetWord);
        String formatedRecognizedWord = formatWord(_recognizedWords[i]);

        _wordMarking[i] = formatedTargetWord == formatedRecognizedWord;
      }
    });
  }

  // Helper method to get word at a flat index from the nested structure
  String _getWordAtIndex(int flatIndex) {
    int wordsSoFar = 0;
    for (var line in _words) {
      if (flatIndex < wordsSoFar + line.length) {
        return line[flatIndex - wordsSoFar];
      }
      wordsSoFar += line.length;
    }
    return ''; // Should not reach here if index is valid
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        ref
                            .read(langProvider.notifier)
                            .prefLangText(
                              const PrefLangText(
                                hindi: 'कृपया आगे बढ़ने के लिए नीचे दिया गया वाक्य बोलें।',
                                hinglish:
                                    'Kripya aage badhne ke liye neeche diya gaya sentence boliye',
                              ),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Display each line in its own Wrap
                    Column(
                      children: [
                        for (int lineIndex = 0; lineIndex < _words.length; lineIndex++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (
                                  int wordIndex = 0;
                                  wordIndex < _words[lineIndex].length;
                                  wordIndex++
                                )
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Calculate the flat index for this word
                                      Builder(
                                        builder: (context) {
                                          int flatIndex = 0;
                                          for (int i = 0; i < lineIndex; i++) {
                                            flatIndex += _words[i].length;
                                          }
                                          flatIndex += wordIndex;

                                          // Recognized word
                                          return Column(
                                            children: [
                                              _recognizedWords[flatIndex].isNotEmpty
                                                  ? Text(
                                                    _recognizedWords[flatIndex],
                                                    style: recognizedWordStyle.copyWith(
                                                      textBaseline: TextBaseline.alphabetic,
                                                    ),
                                                  )
                                                  : const SizedBox(height: recognizedWordHeight),

                                              // Target word
                                              Text(
                                                _words[lineIndex][wordIndex],
                                                style: TextStyle(
                                                  color:
                                                      _wordMarking[flatIndex] == null
                                                          ? Colors.white60
                                                          : _wordMarking[flatIndex] == true
                                                          ? Colors.lightBlue[200]
                                                          : _wordMarking[flatIndex] == false
                                                          ? Colors.red
                                                          : Colors.white,
                                                  fontSize: 24,
                                                  fontWeight:
                                                      _wordMarking[flatIndex] != null
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                  height: 1.4,
                                                  textBaseline: TextBaseline.alphabetic,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (testCompleted)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: passed ? Colors.green[300] : Colors.red[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            passed ? Icons.download_done_rounded : Icons.error_rounded,
                            color: Colors.white,
                            size: 30,
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
