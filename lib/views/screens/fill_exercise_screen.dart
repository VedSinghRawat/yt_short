import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialize option keys
    for (int i = 0; i < widget.exercise.options.length; i++) {
      _optionKeys.add(GlobalKey());
    }
  }

  List<String> _getSentenceParts() {
    final words = widget.exercise.text.split(' ');
    final blankIndex = widget.exercise.blankIndex;

    if (blankIndex >= 0 && blankIndex < words.length) {
      return [words.sublist(0, blankIndex).join(' '), words.sublist(blankIndex + 1).join(' ')];
    }
    return [widget.exercise.text, ''];
  }

  @override
  Widget build(BuildContext context) {
    final sentenceParts = _getSentenceParts();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Hindi header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                    child: const Text(
                      'नीचे दिए गए वाक्य में खाली जगह भरें',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
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
                          constraints: const BoxConstraints(minWidth: 100),
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
                  SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(widget.exercise.options.length, (index) {
                        return SizedBox(
                          width: 100, // Reserve space for each option
                          key: ValueKey('option_space_$index'),
                        );
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
                                // Check if the selected option is correct
                                if (selectedOption == widget.exercise.correctOption) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Correct! Well done!'), backgroundColor: Colors.green),
                                  );
                                  widget.goToNext();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Incorrect. Try again!'), backgroundColor: Colors.red),
                                  );
                                  setState(() {
                                    selectedOption = null;
                                  });
                                }
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
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                left: _getOptionPosition(index, isSelected)['left'],
                top: _getOptionPosition(index, isSelected)['top'],
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
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, double> _getOptionPosition(int index, bool isSelected) {
    if (isSelected) {
      // Position the selected option in the blank area
      return _getBlankPosition();
    } else {
      // Position in the original options row
      return _getOriginalOptionPosition(index);
    }
  }

  Map<String, double> _getBlankPosition() {
    try {
      if (_blankKey.currentContext != null && selectedOption != null) {
        final RenderBox blankBox = _blankKey.currentContext!.findRenderObject() as RenderBox;
        final blankPosition = blankBox.localToGlobal(Offset.zero);
        final blankSize = blankBox.size;

        // Get horizontal center of the blank container
        final blankCenterX = blankPosition.dx + (blankSize.width / 2);

        // Position the word in the middle of the blank area, ABOVE the orange line
        // Container structure: 8px padding + 24px SizedBox + 8px padding + 3px border
        // Position in the center of the 24px SizedBox area
        final wordPositionY = blankPosition.dy - 42; // Top padding + center of blank area

        // Get actual size of the word block if possible
        double wordWidth = 100; // fallback

        if (_optionKeys.length > selectedOption! && _optionKeys[selectedOption!].currentContext != null) {
          try {
            final RenderBox wordBox = _optionKeys[selectedOption!].currentContext!.findRenderObject() as RenderBox;
            wordWidth = wordBox.size.width;
          } catch (e) {
            // Keep fallback values
          }
        }

        // Position the word higher above the orange line
        return {'left': blankCenterX - (wordWidth / 2), 'top': wordPositionY};
      }
    } catch (e) {
      // Fallback if widget not rendered yet
    }

    // Fallback calculation
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return {'left': screenWidth * 0.5 - 50, 'top': screenHeight * 0.45};
  }

  Map<String, double> _getOriginalOptionPosition(int index) {
    // Calculate position in the options area
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 16.0; // Account for screen padding
    final availableWidth = screenWidth - (padding * 2);

    // Calculate positions based on the number of options
    final optionSpacing = availableWidth / widget.exercise.options.length;
    final left = padding + (optionSpacing * index) + (optionSpacing / 2) - 50; // Center each option

    // Try to get the actual vertical position of the options area
    double top;
    try {
      final screenHeight = MediaQuery.of(context).size.height;
      top = screenHeight * 0.65; // Approximate options area position
    } catch (e) {
      top = 400; // Fallback
    }

    return {
      'left': left.clamp(0, screenWidth - 100), // Ensure it stays on screen
      'top': top,
    };
  }
}
