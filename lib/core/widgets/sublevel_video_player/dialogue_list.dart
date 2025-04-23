import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math'; // Import for max function
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
import 'package:myapp/core/services/path_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:myapp/models/user/user.dart';

class DialogueList extends ConsumerStatefulWidget {
  final List<Dialogue> dialogues;
  final Function(double height)? onHeightCalculated;

  const DialogueList({super.key, required this.dialogues, this.onHeightCalculated});

  @override
  ConsumerState<DialogueList> createState() => _DialogueListState();
}

class _DialogueListState extends ConsumerState<DialogueList> {
  late FixedExtentScrollController _scrollController;
  int _selectedDialogueIndex = 0;
  final _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    _scrollController.addListener(() {
      if (!mounted) return;
      final newIndex = _scrollController.selectedItem;
      if (_selectedDialogueIndex != newIndex) {
        setState(() {
          _selectedDialogueIndex = newIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  List<Dialogue> _previousDialogues = [];

  @override
  void didUpdateWidget(covariant DialogueList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(widget.dialogues, _previousDialogues)) return;
    _previousDialogues = List.from(widget.dialogues);

    if (!_scrollController.hasClients || widget.dialogues.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateToItem(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      if (_selectedDialogueIndex == 0) return;
      setState(() => _selectedDialogueIndex = 0);
    });
  }

  Future<void> _playDialogueAudio(String audioFilename) async {
    try {
      await _audioPlayer.stop();

      final filePath = PathService.dialogueAudio(audioFilename);

      // Check if file exists before attempting to play
      final file = File(filePath);
      if (!await file.exists()) {
        developer.log("Audio file not found: $filePath");
        return;
      }

      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();
    } catch (e) {
      developer.log("Error playing dialogue audio: $e");
    }
  }

  // --- Function to Calculate Item Height ---
  double _calculateItemHeight(
    BoxConstraints constraints,
    List<Dialogue> dialogues,
    PrefLang prefLang,
  ) {
    double maxOverallItemHeight = 0;

    final timePainter = TextPainter(
      text: const TextSpan(text: "00:00", style: TextStyle(fontSize: timeFontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    final double maxTimeHeight = timePainter.height;

    const double maxIconHeight = selectedIconSize + (iconPadding * 2) + (iconBorder * 2);
    final double maxNonTextHeight = max(maxTimeHeight, maxIconHeight);

    final double timeTextWidth = timePainter.width;
    const double iconContainerWidth = selectedIconSize + (iconPadding * 2) + (iconBorder * 2);
    const double fixedSpacing = 16.0 + 12.0;
    final double availableWidthForFlexible =
        constraints.maxWidth -
        timeTextWidth -
        iconContainerWidth -
        fixedSpacing -
        (horizontalPadding * 2);
    final double textConstraintWidth = max(0, availableWidthForFlexible * textWidthPercentage);

    const double selectedFontSize = 20;
    const FontWeight selectedFontWeight = FontWeight.bold;
    const double translationFontSize = selectedFontSize * 0.75;

    const mainTextStyle = TextStyle(
      fontSize: selectedFontSize,
      color: Colors.white,
      fontWeight: selectedFontWeight,
    );
    const translationTextStyle = TextStyle(
      fontSize: translationFontSize,
      color: Colors.white70,
      fontWeight: FontWeight.normal,
    );

    for (final dialogue in dialogues) {
      double currentTextColumnHeight = 0;

      final textPainter = TextPainter(
        text: TextSpan(text: dialogue.text, style: mainTextStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: textConstraintWidth);
      currentTextColumnHeight += textPainter.height;

      if (dialogue.hindiText.isNotEmpty && dialogue.hinglishText.isNotEmpty) {
        currentTextColumnHeight += betweenTextPadding;
        final translationText =
            prefLang == PrefLang.hindi ? dialogue.hindiText : dialogue.hinglishText;
        final translationPainter = TextPainter(
          text: TextSpan(text: translationText, style: translationTextStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: textConstraintWidth);
        currentTextColumnHeight += translationPainter.height;
      }

      final double currentItemHeight = max(currentTextColumnHeight, maxNonTextHeight);

      if (currentItemHeight > maxOverallItemHeight) {
        maxOverallItemHeight = currentItemHeight;
      }
    }

    return (maxOverallItemHeight + overallVerticalPadding) * 1.1;
  }
  // --- End Function ---

  @override
  Widget build(BuildContext context) {
    _previousDialogues = List.from(widget.dialogues);

    if (widget.dialogues.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onHeightCalculated?.call(45.0);
      });
      return Center(
        child: Text(
          ref
              .read(langProvider.notifier)
              .prefLangText(
                const PrefLangText(
                  hindi: 'अभी दिखाने के लिए कोई डायलॉग नहीं है',
                  hinglish: 'Abhi dikhane ke liye koi dialogue nahi hai',
                ),
              ),
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      );
    }

    final prefLang = ref.watch(
      userControllerProvider.select((state) => state.currentUser?.prefLang ?? PrefLang.hinglish),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Call the calculation function
        final double calculatedItemHeight = _calculateItemHeight(
          constraints,
          widget.dialogues,
          prefLang,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onHeightCalculated?.call(calculatedItemHeight);
        });

        return Stack(
          children: [
            ListWheelScrollView.useDelegate(
              controller: _scrollController,
              itemExtent: calculatedItemHeight,
              diameterRatio: 2.3,
              perspective: 0.004,
              physics: const FixedExtentScrollPhysics(),
              childDelegate: ListWheelChildListDelegate(
                children: List<Widget>.generate(widget.dialogues.length, (index) {
                  final dialogue = widget.dialogues[index];
                  final formattedTime = formatDurationMMSS(dialogue.time);
                  final bool isSelected = index == _selectedDialogueIndex;

                  final double textFontSize = isSelected ? 20 : 18;
                  final FontWeight textFontWeight = isSelected ? FontWeight.bold : FontWeight.w500;
                  final double iconSize = isSelected ? 20 : 18;
                  final Color timeColor = isSelected ? Colors.white : Colors.white70;
                  final Color iconColor = isSelected ? Colors.white : Colors.white70;
                  // Constants needed inside the loop, moved outside the height calculation function
                  const double horizontalPadding = 16.0;
                  const double textWidthPercentage = 0.7;
                  const double betweenTextPadding = 2.0;

                  return Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(formattedTime, style: TextStyle(fontSize: 12, color: timeColor)),
                        const SizedBox(width: 16),
                        Flexible(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Inner LayoutBuilder might still be needed if text width depends on Flexible allocation
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                                child: SizedBox(
                                  width: constraints.maxWidth * textWidthPercentage,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        dialogue.text,
                                        style: TextStyle(
                                          fontSize: textFontSize,
                                          color: Colors.white,
                                          fontWeight: textFontWeight,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (dialogue.hindiText.isNotEmpty &&
                                          dialogue.hinglishText.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: betweenTextPadding),
                                          child: Text(
                                            prefLang == PrefLang.hindi
                                                ? dialogue.hindiText
                                                : dialogue.hinglishText,
                                            style: TextStyle(
                                              fontSize: textFontSize * 0.75,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            await _playDialogueAudio(dialogue.audioFilename);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((255 * 0.2).round()),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white70, width: 1),
                            ),
                            child: Icon(Icons.volume_up, color: iconColor, size: iconSize),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: calculatedItemHeight,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.black.withAlpha(0)],
                      stops: const [0.0, 0.9],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: calculatedItemHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.black.withAlpha(0)],
                      stops: const [0.0, 0.9],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

const double horizontalPadding = 16.0;
const double textWidthPercentage = 0.7;
const double betweenTextPadding = 2.0;
const double overallVerticalPadding = 16.0;
const double timeFontSize = 12.0;
const double selectedIconSize = 20.0;
const double iconPadding = 4.0;
const double iconBorder = 1.0;
