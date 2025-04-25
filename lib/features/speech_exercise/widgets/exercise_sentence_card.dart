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
  final VoidCallback onClose;

  const SpeechExerciseCard({
    super.key,
    required this.text,
    required this.onContinue,
    required this.levelId,
    required this.audioFilename,
    required this.onClose,
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
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.2), blurRadius: 12.0, spreadRadius: 4.0),
        ],
      ),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CloseButton(onClose: widget.onClose),
          Column(
            children: [
              // Top bar with heading and close button
              const Header(),
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24.0),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        // Listen button with icon
                        Container(
                          margin: const EdgeInsets.only(bottom: 24.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                ref
                                    .read(speechProvider.notifier)
                                    .playAudio(widget.levelId, widget.audioFilename);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      speechState.isPlayingAudio
                                          ? Icons.hearing_rounded
                                          : Icons.hearing_outlined,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      ref
                                          .watch(langProvider.notifier)
                                          .prefLangText(
                                            PrefLangText(
                                              hindi:
                                                  speechState.isPlayingAudio
                                                      ? 'सुन रहे हैं...'
                                                      : 'सुनें',
                                              hinglish:
                                                  speechState.isPlayingAudio
                                                      ? 'Sun rahe hain...'
                                                      : 'Sune',
                                            ),
                                          ),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        Column(
                          children: [
                            for (int lineIndex = 0; lineIndex < _words.length; lineIndex++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  children: [
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
                                                          speechState.wordMarking.elementAtOrNull(
                                                                    flatIndex,
                                                                  ) ==
                                                                  null
                                                              ? Colors.white60
                                                              : speechState.wordMarking
                                                                      .elementAtOrNull(flatIndex) ==
                                                                  true
                                                              ? Colors.lightBlue[200]
                                                              : speechState.wordMarking
                                                                      .elementAtOrNull(flatIndex) ==
                                                                  false
                                                              ? Colors.red
                                                              : Colors.white,
                                                      fontSize: 24,
                                                      fontWeight:
                                                          speechState.wordMarking.elementAtOrNull(
                                                                    flatIndex,
                                                                  ) !=
                                                                  null
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
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(9.0),
      child: Center(
        child: Text(
          'Speech Exercise',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class CloseButton extends StatelessWidget {
  const CloseButton({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -10,
      top: -10,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey[400]!.withValues(alpha: .2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: Colors.grey[400]!, width: 1.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: InkWell(
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.close_rounded, size: 20, color: Colors.grey[400]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
