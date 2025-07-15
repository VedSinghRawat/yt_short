import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/models/fill_exercise/fill_exercise.dart';

class FillExerciseScreen extends ConsumerStatefulWidget {
  final FillExercise exercise;
  final VoidCallback goToNext;

  const FillExerciseScreen({super.key, required this.exercise, required this.goToNext});

  @override
  ConsumerState<FillExerciseScreen> createState() => _FillExerciseScreenState();
}

class _FillExerciseScreenState extends ConsumerState<FillExerciseScreen> {
  int? selectedOption;
  final GlobalKey _blankKey = GlobalKey();
  final List<GlobalKey> _optionKeys = [];
  final List<GlobalKey> _placeholderKeys = [];
  final GlobalKey _optionsAreaKey = GlobalKey();
  bool hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize option keys and placeholder keys
    for (int i = 0; i < widget.exercise.options.length; i++) {
      _optionKeys.add(GlobalKey());
      _placeholderKeys.add(GlobalKey());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Small delay to ensure all widgets are fully rendered
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {});
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          hasInitialized = true;
        });
      });
    });
  }

  List<String> _getSentenceParts() {
    final words = widget.exercise.text.split(' ');
    final blankIndex = widget.exercise.blankIndex;

    if (blankIndex >= 0 && blankIndex < words.length) {
      return [words.sublist(0, blankIndex).join(' '), words.sublist(blankIndex + 1).join(' ')];
    }
    return [widget.exercise.text, ''];
  }

  Size _calculateTextSize(String text) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Add padding (24px horizontal + 12px vertical padding from the container)
    return Size(
      textPainter.width + 48, // 24px padding on each side
      textPainter.height + 24, // 12px padding on top and bottom
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
    return maxWidth + 20;
  }

  Map<String, double> _getOptionPosition(int index, bool isSelected) =>
      isSelected ? _getBlankPosition() : _getOriginalOptionPosition(index);

  Map<String, double> _getBlankPosition() {
    try {
      if (_blankKey.currentContext != null && selectedOption != null) {
        final RenderBox blankBox = _blankKey.currentContext!.findRenderObject() as RenderBox;
        final blankPosition = blankBox.localToGlobal(Offset.zero);
        final blankSize = blankBox.size;

        // Get the actual size of the selected word
        final selectedText = widget.exercise.options[selectedOption!];
        final wordSize = _calculateTextSize(selectedText);

        // Center the word horizontally within the blank space
        final blankCenterX = blankPosition.dx + (blankSize.width / 2);
        final wordPositionX = blankCenterX - (wordSize.width / 2);

        // Position the word vertically centered in the blank area
        // The blank container has 8px padding top/bottom, so center it within that space
        final blankCenterY = blankPosition.dy + (blankSize.height / 2);
        final wordPositionY = blankCenterY - (wordSize.height / 2);

        return {'left': wordPositionX, 'top': wordPositionY - 100};
      }
    } catch (e) {
      developer.log('Error calculating blank position: $e');
    }

    // Fallback calculation
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (selectedOption != null) {
      final wordSize = _calculateTextSize(widget.exercise.options[selectedOption!]);
      return {'left': (screenWidth / 2) - (wordSize.width / 2), 'top': screenHeight * 0.45};
    }

    return {'left': screenWidth * 0.5 - 50, 'top': screenHeight * 0.45};
  }

  Map<String, double> _getOriginalOptionPosition(int index) {
    try {
      // Get the position directly from the placeholder's GlobalKey
      if (_placeholderKeys[index].currentContext != null) {
        final RenderBox placeholderBox = _placeholderKeys[index].currentContext!.findRenderObject() as RenderBox;
        final position = placeholderBox.localToGlobal(Offset.zero);
        return {'left': position.dx, 'top': position.dy - 80};
      }
    } catch (e) {
      developer.log('Error getting placeholder position: $e');
    }

    // Fallback calculation
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return {'left': (screenWidth / 2) - 50, 'top': screenHeight * 0.65};
  }

  @override
  Widget build(BuildContext context) {
    final sentenceParts = _getSentenceParts();
    final theme = Theme.of(context);
    final langController = ref.read(langControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
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
                        Text(
                          langController.choose(hindi: 'रिक्त स्थान भरें', hinglish: 'Fill in the Blank'),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          langController.choose(
                            hindi: 'छवि के हिसाब से सही शब्द चुनकर रिक्त स्थान भरें।',
                            hinglish: 'Image ke hisaab se sahi word se blank ko fill karein.',
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
                  ),

                  const SizedBox(height: 20),

                  // Content area placeholder
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Icon(Icons.image, size: 60, color: Colors.grey[600])),
                  ),

                  const Spacer(),

                  // Sentence with blank
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (sentenceParts[0].isNotEmpty)
                          Text(
                            '${sentenceParts[0]} ',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400),
                          ),
                        Container(
                          key: _blankKey,
                          constraints: BoxConstraints(minWidth: _getWidestOptionWidth()),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.orange, width: 3)),
                          ),
                          child: const SizedBox(height: 24), // Empty space for the blank
                        ),
                        if (sentenceParts[1].isNotEmpty)
                          Text(
                            ' ${sentenceParts[1]}',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Multiple choice options area (empty space for positioning)
                  Container(
                    key: _optionsAreaKey,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 18.0,
                      runSpacing: 18.0,
                      children: List.generate(widget.exercise.options.length, (index) {
                        final textSize = _calculateTextSize(widget.exercise.options[index]);
                        return SizedBox(width: textSize.width, height: textSize.height, key: _placeholderKeys[index]);
                      }),
                    ),
                  ),

                  const Spacer(),

                  // Check button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed:
                          selectedOption != null
                              ? () {
                                final isCorrect = selectedOption == widget.exercise.correctOption;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isCorrect ? 'Correct! Well done!' : 'Incorrect. Try again!'),
                                    backgroundColor: isCorrect ? Colors.green : Colors.red,
                                  ),
                                );

                                isCorrect ? widget.goToNext() : setState(() => selectedOption = null);
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.grey[600],
                      ),
                      child: const Text('Check', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Animated positioned option buttons
            ...List.generate(widget.exercise.options.length, (index) {
              final isSelected = selectedOption == index;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                left: _getOptionPosition(index, isSelected)['left'],
                top: _getOptionPosition(index, isSelected)['top'],
                child: AnimatedOpacity(
                  opacity: hasInitialized ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedOption = selectedOption == index ? null : index;
                      });
                    },
                    child: Container(
                      key: _optionKeys[index],
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange : Colors.grey[700],
                        borderRadius: BorderRadius.circular(25),
                        boxShadow:
                            isSelected
                                ? [BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                                : null,
                      ),
                      child: Text(
                        widget.exercise.options[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[300],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
