import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/controllers/speech/speech_controller.dart';
import 'package:myapp/views/widgets/speech_exercise/recognizer_button.dart';

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

    final textToShow = <String>[]; // Initialize an empty list for words to show
    for (var i = 0; i < speechState.recognizedWords.length; i++) {
      String word = speechState.recognizedWords[i];
      if (word.isEmpty) continue;
      if (i == 0) {
        word = word[0].toUpperCase() + word.substring(1);
      }
      textToShow.add(word);
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.2), blurRadius: 12.0, spreadRadius: 4.0)],
      ),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // Top bar with heading and close button
              const Header(),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, bottom: 8.0), // Outer padding
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                ref
                                    .read(langControllerProvider.notifier)
                                    .choose(hindi: 'नीचे दिया वाक्य बोलें:', hinglish: 'Niche diya vakya bole:'),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(15.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: .25),
                                      spreadRadius: 2,
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
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
                                                    margin:
                                                        mark != null ? const EdgeInsets.symmetric(vertical: 2) : null,
                                                    decoration: BoxDecoration(
                                                      color: backgroundColor,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      _words[lineIndex][wordIndex],
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: fontWeight,
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
                              bottom: 20,
                              right: 20,
                              child: Material(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(30),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: () {
                                    ref.read(speechProvider.notifier).playAudio(widget.levelId, widget.audioFilename);
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
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSecondary,
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
                          padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                ref
                                    .read(langControllerProvider.notifier)
                                    .choose(hindi: 'आपने कहा:', hinglish: 'Aapne kaha:'),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color:
                                  !speechNotifier.isTestCompleted
                                      ? Theme.of(context).colorScheme.primary
                                      : speechNotifier.isPassed
                                      ? Colors.green[400]
                                      : Colors.red[400],
                              borderRadius: BorderRadius.circular(15.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${textToShow.join(' ')}${_flatWords.length == textToShow.length ? '.' : ''}',
                              style: recognizedWordStyle.copyWith(
                                color:
                                    !speechNotifier.isTestCompleted
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Colors.white,
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

          CloseButton(onClose: widget.onClose),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Text(
          'Speech Exercise',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
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
          boxShadow: [BoxShadow(color: Colors.grey[400]!.withValues(alpha: .2), blurRadius: 10, spreadRadius: 2)],
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
