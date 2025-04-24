import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
import 'package:myapp/features/speech_exercise/providers/speech_provider.dart';
import 'package:myapp/features/speech_exercise/widgets/recognizer_button.dart';

class SpeechExerciseCard extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback onContinue;
  final String levelId;
  final String audioFilename;

  const SpeechExerciseCard({
    super.key,
    required this.text,
    required this.onContinue,
    required this.levelId,
    required this.audioFilename,
  });

  @override
  ConsumerState<SpeechExerciseCard> createState() => _SpeechExerciseCardState();
}

class _SpeechExerciseCardState extends ConsumerState<SpeechExerciseCard> {
  late List<List<String>> _words;
  late List<String> _flatWords;

  @override
  void initState() {
    super.initState();
    _words = [];
    _flatWords = [];

    // Split text by new lines to maintain line structure
    final lines = widget.text.split('\n');
    for (var line in lines) {
      List<String> lineWords = [];
      for (var word in line.split(' ')) {
        word = word.trim();
        if (word.isNotEmpty) {
          lineWords.add(word);
          _flatWords.add(word);
        }
      }
      if (lineWords.isNotEmpty) {
        _words.add(lineWords);
      }
    }

    // Initialize the speech provider with target words
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(speechProvider.notifier).setTargetWords(_flatWords);
    });
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechProvider);
    final speechNotifier = ref.read(speechProvider.notifier);

    // Match font sizes and line heights to keep total vertical space in sync
    const double recognizedWordFontSize = 24;
    const double recognizedWordLineHeight = 1.4; // Adjust if needed

    final recognizedWordStyle = TextStyle(
      color: Colors.grey[400],
      fontSize: recognizedWordFontSize,
      fontWeight: FontWeight.w300,
      height: recognizedWordLineHeight,
    );
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
                            child: Column(
                              children: [
                                Center(
                                  child: IconButton(
                                    onPressed: () {
                                      ref
                                          .read(speechProvider.notifier)
                                          .playAudio(widget.levelId, widget.audioFilename);
                                    },
                                    icon: const Icon(Icons.hearing_sharp),
                                    color: Colors.blue,
                                    iconSize: 30,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 2,
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

                                              // Target word - Now directly returned by Builder
                                              return Text(
                                                _words[lineIndex][wordIndex],
                                                style: TextStyle(
                                                  color:
                                                      speechState.wordMarking[flatIndex] == null
                                                          ? Colors.white60
                                                          : speechState.wordMarking[flatIndex] ==
                                                              true
                                                          ? Colors.lightBlue[200]
                                                          : speechState.wordMarking[flatIndex] ==
                                                              false
                                                          ? Colors.red
                                                          : Colors.white,
                                                  fontSize: 24,
                                                  fontWeight:
                                                      speechState.wordMarking[flatIndex] != null
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                  height: 1.4,
                                                  textBaseline: TextBaseline.alphabetic,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (speechNotifier.isTestCompleted)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: speechNotifier.isPassed ? Colors.green[300] : Colors.red[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            speechNotifier.isPassed
                                ? Icons.download_done_rounded
                                : Icons.error_rounded,
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
          // Display recognized words at the bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              speechState.recognizedWords.where((w) => w.isNotEmpty).join(' '),
              style: recognizedWordStyle,
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: RecognizerButton(onContinue: widget.onContinue),
          ),
        ],
      ),
    );
  }
}
