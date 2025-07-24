import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/fill_exercise/fill_exercise.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:myapp/views/widgets/sublevel_image.dart';
import 'package:myapp/views/widgets/lang_text.dart';

class FillExerciseScreen extends ConsumerStatefulWidget {
  final FillExercise exercise;
  final VoidCallback goToNext;
  final bool isCurrent;

  const FillExerciseScreen({super.key, required this.exercise, required this.goToNext, required this.isCurrent});

  @override
  ConsumerState<FillExerciseScreen> createState() => _FillExerciseScreenState();
}

class _FillExerciseScreenState extends ConsumerState<FillExerciseScreen> {
  // Padding constants for text elements
  static const double _textHorizontalPadding = 16.0;
  static const double _textVerticalPadding = 10.0;
  static const double _optionButtonHorizontalPadding = 18.0;
  static const double _optionButtonVerticalPadding = 6.0;
  static const double _additionalWidthPadding = 20.0;
  static const double _blankHorizontalPadding = 8.0;
  static const double _blankVerticalPadding = 6.0;
  static const double _positionAdjustment = 6.0;

  int? selectedOption;
  final GlobalKey _blankKey = GlobalKey();
  final List<GlobalKey> _optionKeys = [];
  final List<GlobalKey> _placeholderKeys = [];
  final GlobalKey _optionsAreaKey = GlobalKey();
  bool hasInitialized = false;
  bool _isCorrect = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    // Initialize option keys and placeholder keys
    for (int i = 0; i < widget.exercise.options.length; i++) {
      _optionKeys.add(GlobalKey());
      _placeholderKeys.add(GlobalKey());
    }
  }

  @override
  void didUpdateWidget(FillExerciseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if isVisible changed from true to false (user scrolled away)
    if (oldWidget.isCurrent && !widget.isCurrent) {
      // Reset all user interactions
      setState(() {
        selectedOption = null;
        hasInitialized = false;
        _isCorrect = false;
        _isAnimating = false;
      });
    }
  }

  List<String> _getSentenceParts() {
    final words = widget.exercise.text.split(' ');
    final blankIndex = widget.exercise.blankIndex;

    if (blankIndex >= 0 && blankIndex <= words.length) {
      return [words.sublist(0, blankIndex).join(' '), words.sublist(blankIndex).join(' ')];
    }
    return [widget.exercise.text, ''];
  }

  Size _calculateTextSize(String text) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Add padding using constants
    return Size(
      textPainter.width + (_textHorizontalPadding * 2), // horizontal padding on each side
      textPainter.height + (_textVerticalPadding * 2), // vertical padding on top and bottom
    );
  }

  double _getWidestOptionWidth() {
    double maxWidth = 0;
    for (String option in widget.exercise.options) {
      final size = _calculateTextSize(option);
      if (size.width > maxWidth) {
        maxWidth = size.width;
      }
    }
    return maxWidth + _additionalWidthPadding;
  }

  Map<String, double> _getBlankPosition() {
    try {
      if (_blankKey.currentContext == null) return {'left': 0, 'top': 0};

      final RenderBox blankBox = _blankKey.currentContext!.findRenderObject() as RenderBox;
      final blankPosition = blankBox.localToGlobal(Offset.zero);

      final selectedTextSize = _calculateTextSize(widget.exercise.options[selectedOption!]);

      return {
        'left': blankPosition.dx + blankBox.size.width / 2 - selectedTextSize.width / 2 - _positionAdjustment,
        'top': blankPosition.dy - selectedTextSize.height * 1.5 - _positionAdjustment,
      };
    } catch (e) {
      developer.log('Error getting blank position: $e');
    }

    return {'left': 0, 'top': 0};
  }

  Map<String, double> _getOriginalOptionPosition(int index) {
    try {
      // Get the position directly from the placeholder's GlobalKey
      if (_placeholderKeys[index].currentContext != null) {
        final RenderBox placeholderBox = _placeholderKeys[index].currentContext!.findRenderObject() as RenderBox;
        final position = placeholderBox.localToGlobal(Offset.zero);
        return {'left': position.dx, 'top': position.dy - 52};
      }
    } catch (e) {
      developer.log('Error getting placeholder position: $e');
    }
    return {'left': 0, 'top': 0};
  }

  void _checkAnswer() {
    if (selectedOption == widget.exercise.correctOption) {
      setState(() {
        _isCorrect = true;
      });
    } else {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LangText.body(
            hindi: 'गलत उत्तर है, फिर से कोशिश करें',
            hinglish: 'Galat uttar hai, firse koshish kare',
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );

      // Reset selection
      setState(() {
        selectedOption = null;
        _isAnimating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentenceParts = _getSentenceParts();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: VisibilityDetector(
          key: ValueKey(widget.exercise.id),
          onVisibilityChanged: (visibility) {
            if (!hasInitialized && visibility.visibleFraction != 1 || !mounted) return;

            setState(() {
              hasInitialized = visibility.visibleFraction == 1;
            });
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
                child: Column(
                  children: [
                    // Hindi header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          LangText.heading(
                            hindi: 'रिक्त स्थान भरें',
                            hinglish: 'Fill in the Blank',
                            style: TextStyle(color: theme.colorScheme.onPrimary),
                          ),
                          const SizedBox(height: 8),
                          LangText.body(
                            hindi: 'छवि के अनुसार वाक्य में उचित विकल्प चुनकर रिक्त स्थान भरें।',
                            hinglish: 'Chavi ke anusar vakya mein uchit vikalp chunkar rikta sthan bhariye.',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[800]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SubLevelImage(levelId: widget.exercise.levelId, sublevelId: widget.exercise.id),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sentence with blank
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (sentenceParts[0].isNotEmpty)
                          LangText.bodyText(
                            text: '${sentenceParts[0]} ',
                            style: const TextStyle(color: Colors.white, fontSize: 24),
                          ),
                        Container(
                          key: _blankKey,
                          constraints: BoxConstraints(minWidth: _getWidestOptionWidth()),
                          padding: const EdgeInsets.symmetric(
                            horizontal: _blankHorizontalPadding,
                            vertical: _blankVerticalPadding,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.orange, width: 3)),
                          ),
                          child: const SizedBox(height: 20), // Reduced height for the blank
                        ),
                        if (sentenceParts[1].isNotEmpty)
                          LangText.bodyText(
                            text: ' ${sentenceParts[1]}',
                            style: const TextStyle(color: Colors.white, fontSize: 24),
                          ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Multiple choice options area with normal buttons
                    Container(
                      key: _optionsAreaKey,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20.0,
                        runSpacing: 14.0,
                        children: List.generate(widget.exercise.options.length, (index) {
                          final isSelected = selectedOption == index;

                          // If this option is selected, show placeholder, otherwise show the actual button
                          if (isSelected) {
                            final textSize = _calculateTextSize(widget.exercise.options[index]);
                            return SizedBox(
                              width: textSize.width,
                              height: textSize.height,
                              key: _placeholderKeys[index],
                            );
                          }

                          return GestureDetector(
                            key: _placeholderKeys[index],
                            onTap: () {
                              // If there's already a selection, reset first
                              if (selectedOption != null) {
                                setState(() {
                                  selectedOption = null;
                                  _isAnimating = false;
                                });

                                // Small delay before setting new selection
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  if (mounted) {
                                    setState(() {
                                      selectedOption = index;
                                      _isAnimating = false;
                                    });

                                    // Start animation after a brief delay
                                    Future.delayed(const Duration(milliseconds: 50), () {
                                      if (mounted) {
                                        setState(() {
                                          _isAnimating = true;
                                        });
                                      }
                                    });
                                  }
                                });
                              } else {
                                // No previous selection, animate normally
                                setState(() {
                                  selectedOption = index;
                                  _isAnimating = false;
                                });

                                // Start animation after a brief delay
                                Future.delayed(const Duration(milliseconds: 50), () {
                                  if (mounted) {
                                    setState(() {
                                      _isAnimating = true;
                                    });
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: _optionButtonVerticalPadding,
                                horizontal: _optionButtonHorizontalPadding,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: LangText.bodyText(
                                text: widget.exercise.options[index],
                                style: TextStyle(color: Colors.grey[300], fontSize: 18),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const Spacer(),

                    _isCorrect
                        ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.goToNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[400],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              child: const LangText.body(hindi: 'आगे बढ़ें', hinglish: 'Aage badhe'),
                            ),
                          ),
                        )
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: selectedOption != null ? _checkAnswer : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                disabledBackgroundColor: Colors.grey[600],
                              ),
                              child: const LangText.body(hindi: 'जांचें', hinglish: 'Check'),
                            ),
                          ),
                        ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Only show positioned widget for selected option
              if (hasInitialized && selectedOption != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  left:
                      _isAnimating ? _getBlankPosition()['left'] : _getOriginalOptionPosition(selectedOption!)['left'],
                  top: _isAnimating ? _getBlankPosition()['top'] : _getOriginalOptionPosition(selectedOption!)['top'],
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedOption = null;
                        _isAnimating = false;
                      });
                    },
                    child: Container(
                      key: _optionKeys[selectedOption!],
                      padding: const EdgeInsets.symmetric(
                        vertical: _optionButtonVerticalPadding,
                        horizontal: _optionButtonHorizontalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2),
                        ],
                      ),
                      child: LangText.bodyText(
                        text: widget.exercise.options[selectedOption!],
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
