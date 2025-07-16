import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/controllers/speech/speech_controller.dart';
import 'package:myapp/views/widgets/speech_exercise/recognizer_button.dart';

class SpeechExerciseCard extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback onContinue;
  final String levelId;
  final String id;
  final VoidCallback? onClose;

  const SpeechExerciseCard({
    super.key,
    required this.text,
    required this.onContinue,
    required this.levelId,
    required this.id,
    this.onClose,
  });

  @override
  ConsumerState<SpeechExerciseCard> createState() => _SpeechExerciseCardState();
}

class _SpeechExerciseCardState extends ConsumerState<SpeechExerciseCard> {
  late List<List<String>> _words;
  late List<String> _flatWords;
  bool _isVisible = false;

  void _processText(String text) {
    _words = [];
    _flatWords = [];

    // Split text by new lines to maintain line structure
    final lines = text.split('\n');

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
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0.3; // Consider visible if more than 50% is visible

    if (isVisible && !_isVisible) {
      // Card became visible - initialize speech controller
      _isVisible = true;

      if (ref.read(speechProvider).currentExerciseId == widget.id) return;

      // Process text and initialize speech controller
      _processText(widget.text);
      ref.read(speechProvider.notifier).setTargetWords(_flatWords, widget.id);
    } else if (!isVisible && _isVisible) {
      _isVisible = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _processText(widget.text);
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

    final textToShow = <String>[]; // Initialize an empty list for words to show
    for (var i = 0; i < speechState.recognizedWords.length; i++) {
      String word = speechState.recognizedWords[i];
      if (word.isEmpty) continue;
      if (i == 0) {
        word = word[0].toUpperCase() + word.substring(1);
      }
      textToShow.add(word);
    }

    return VisibilityDetector(
      key: Key(widget.id),
      onVisibilityChanged: _onVisibilityChanged,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with heading
            const Header(),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  Column(
                    children: [
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.grey[700]!, width: 2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 44.0, top: 24.0, left: 18.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (int lineIndex = 0; lineIndex < _words.length; lineIndex++)
                                      Wrap(
                                        spacing: 8,
                                        alignment: WrapAlignment.start,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          for (int wordIndex = 0; wordIndex < _words[lineIndex].length; wordIndex++)
                                            Builder(
                                              builder: (context) {
                                                int flatIndex = 0;
                                                for (int i = 0; i < lineIndex; i++) {
                                                  flatIndex += _words[i].length;
                                                }
                                                flatIndex += wordIndex;

                                                // Determine color based on marking
                                                Color? backgroundColor;
                                                FontWeight fontWeight = FontWeight.w600;
                                                final mark = speechState.wordMarking.elementAtOrNull(flatIndex);
                                                if (mark == true) {
                                                  backgroundColor = const Color.fromARGB(255, 8, 85, 10);
                                                  fontWeight = FontWeight.bold;
                                                } else if (mark == false) {
                                                  // false
                                                  backgroundColor = Colors.redAccent;
                                                  fontWeight = FontWeight.normal;
                                                }

                                                return Container(
                                                  padding:
                                                      mark != null
                                                          ? const EdgeInsets.symmetric(horizontal: 5, vertical: 4)
                                                          : null,
                                                  margin: mark != null ? const EdgeInsets.symmetric(vertical: 2) : null,
                                                  decoration: BoxDecoration(
                                                    color: backgroundColor,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    _words[lineIndex][wordIndex],
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: fontWeight,
                                                      color: Colors.grey[300],
                                                      textBaseline: TextBaseline.alphabetic,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            right: 24,
                            child: Material(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(30),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () {
                                  ref.read(speechProvider.notifier).playAudio(widget.levelId, widget.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        speechState.isPlayingAudio ? Icons.hearing_rounded : Icons.hearing_outlined,
                                        size: 18,
                                        color: Theme.of(context).colorScheme.onSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        ref
                                            .read(langControllerProvider.notifier)
                                            .choose(
                                              hindi: speechState.isPlayingAudio ? 'सुन रहे हैं...' : 'सुनें',
                                              hinglish: speechState.isPlayingAudio ? 'Sun rahe hain...' : 'Sune',
                                            ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color:
                                !speechNotifier.isTestCompleted
                                    ? Colors.grey[900]
                                    : speechNotifier.isPassed
                                    ? Colors.green[400]
                                    : Colors.red[400],
                            borderRadius: BorderRadius.circular(12.0),
                            border:
                                !speechNotifier.isTestCompleted ? Border.all(color: Colors.grey[700]!, width: 2) : null,
                          ),
                          child: Text(
                            '${textToShow.join(' ')}${_flatWords.length == textToShow.length ? '.' : ''}',
                            style: recognizedWordStyle.copyWith(
                              color: !speechNotifier.isTestCompleted ? Colors.grey[300] : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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
              child: RecognizerButton(onContinue: widget.onContinue),
            ),
          ],
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        final langController = ref.read(langControllerProvider.notifier);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Text(
                langController.choose(hindi: 'स्पीच एक्सरसाइज़', hinglish: 'Speech Exercise'),
                style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                langController.choose(
                  hindi: 'नीचे दिया गया वाक्य सही उच्चारण के साथ बोलें।',
                  hinglish: 'Niche diya gaya vakya sahi ucharan ke saath bole.',
                ),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
