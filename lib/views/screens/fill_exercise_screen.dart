import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/fill_exercise/fill_exercise.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:myapp/views/widgets/sublevel_image.dart';
import 'package:myapp/views/widgets/lang_text.dart';
import 'package:myapp/views/widgets/exercise_container.dart';
import 'package:myapp/core/shared_pref.dart';

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
  static const double _optionButtonHorizontalPadding = 18.0;
  static const double _optionButtonVerticalPadding = 6.0;
  static const double _blankHorizontalPadding = 8.0;
  static const double _blankVerticalPadding = 6.0;

  int? selectedOption;
  final GlobalKey _blankKey = GlobalKey();
  final List<GlobalKey> _optionKeys = [];
  final List<GlobalKey> _placeholderKeys = [];
  final GlobalKey _optionsAreaKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  bool _isCorrect = false;
  bool _isAnimating = false;
  bool _showDescription = true;

  // Store calculated button sizes
  List<Size> _buttonSizes = [];
  double _widestOptionWidth = 0;

  // Store calculated blank position
  Map<String, double> _blankPosition = {'left': 0, 'top': 0};

  @override
  void initState() {
    super.initState();
    // Initialize option keys and placeholder keys
    if (widget.exercise.options.isNotEmpty) {
      for (int i = 0; i < widget.exercise.options.length; i++) {
        _optionKeys.add(GlobalKey());
        _placeholderKeys.add(GlobalKey());
      }
    }

    // Check if description for Fill exercise has been seen
    final seenMap = SharedPref.get(PrefKey.exercisesSeen) ?? <String, bool>{};
    final hasSeen = seenMap['fill'] == true;
    _showDescription = !hasSeen;
    if (!hasSeen) {
      Future.microtask(() async {
        final updated = Map<String, bool>.from(seenMap);
        updated['fill'] = true;
        await SharedPref.store(PrefKey.exercisesSeen, updated);
      });
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
        _isCorrect = false;
        _isAnimating = false;
        _buttonSizes.clear();
        _widestOptionWidth = 0;
        _blankPosition = {'left': 0, 'top': 0};
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

  void _calculateAndStoreButtonSizes() {
    // Safety check - ensure we have options and keys
    if (widget.exercise.options.isEmpty || _optionKeys.isEmpty) {
      return;
    }

    // Safety check - ensure lengths match
    if (_optionKeys.length != widget.exercise.options.length) {
      return;
    }

    // Check if all contexts are available
    bool allContextsAvailable = true;
    for (int i = 0; i < _optionKeys.length; i++) {
      if (_optionKeys[i].currentContext == null) {
        allContextsAvailable = false;
        break;
      }
    }

    // If not all contexts are ready, retry after 150ms
    if (!allContextsAvailable) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _calculateAndStoreButtonSizes();
        }
      });
      return;
    }

    // All contexts are available, calculate sizes
    _buttonSizes = List.generate(widget.exercise.options.length, (index) {
      try {
        final RenderBox buttonBox = _optionKeys[index].currentContext!.findRenderObject() as RenderBox;
        return buttonBox.size;
      } catch (e) {
        developer.log('Error getting button size for index $index: $e');
        rethrow; // This should not happen if we checked contexts above
      }
    });

    // Calculate and store the widest option width
    _widestOptionWidth = 0;
    for (final size in _buttonSizes) {
      if (size.width > _widestOptionWidth) {
        _widestOptionWidth = size.width;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _calculateAndStoreBlankPosition() {
    try {
      if (_blankKey.currentContext != null && _stackKey.currentContext != null) {
        final RenderBox blankBox = _blankKey.currentContext!.findRenderObject() as RenderBox;
        final RenderBox stackBox = _stackKey.currentContext!.findRenderObject() as RenderBox;

        // Get blank position relative to the Stack container instead of global coordinates
        final Offset relativePosition = blankBox.localToGlobal(Offset.zero, ancestor: stackBox);

        _blankPosition = {
          'left': relativePosition.dx,
          'top': relativePosition.dy,
          'width': blankBox.size.width,
          'height': blankBox.size.height,
        };
      } else {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            _calculateAndStoreBlankPosition();
          }
        });
      }
    } catch (e) {
      developer.log('Error calculating blank position: $e');
    }
  }

  Map<String, double> _getTargetPosition() {
    if (selectedOption == null) return {'left': 0, 'top': 0};

    try {
      final selectedButtonSize = _buttonSizes[selectedOption!];

      return {
        'left': _blankPosition['left']! + (_blankPosition['width']! - selectedButtonSize.width) / 2,
        'top': _blankPosition['top']! - 10,
      };
    } catch (e) {
      developer.log('Error getting blank position: $e');
    }

    return {'left': 0, 'top': 0};
  }

  Map<String, double> _getOriginalOptionPosition(int index) {
    try {
      if (_placeholderKeys[index].currentContext != null && _stackKey.currentContext != null) {
        final RenderBox placeholderBox = _placeholderKeys[index].currentContext!.findRenderObject() as RenderBox;
        final RenderBox stackBox = _stackKey.currentContext!.findRenderObject() as RenderBox;

        // Get position relative to Stack container
        final Offset relativePosition = placeholderBox.localToGlobal(Offset.zero, ancestor: stackBox);
        return {'left': relativePosition.dx, 'top': relativePosition.dy};
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

  void _initialize() {
    // Calculate button sizes and blank position after this frame when all widgets are rendered
    if (_buttonSizes.isEmpty || _blankPosition['width'] == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calculateAndStoreButtonSizes();
          _calculateAndStoreBlankPosition();
        }
      });
    }
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          LangText.heading(
            hindi: 'रिक्त स्थान भरें',
            hinglish: 'Fill in the Blank',
            style: TextStyle(color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(height: 8),
          if (_showDescription)
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
    );
  }

  Widget _buildImage() {
    return SizedBox(
      height: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SubLevelImage(levelId: widget.exercise.levelId, sublevelId: widget.exercise.id),
      ),
    );
  }

  Widget _buildContent() {
    final sentenceParts = _getSentenceParts();

    return Column(
      children: [
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
              constraints: BoxConstraints(minWidth: _widestOptionWidth),
              padding: const EdgeInsets.symmetric(horizontal: _blankHorizontalPadding, vertical: _blankVerticalPadding),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.orange, width: 3))),
              child: const SizedBox(height: 20),
            ),
            if (sentenceParts[1].isNotEmpty)
              LangText.bodyText(
                text: ' ${sentenceParts[1]}',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
          ],
        ),

        const SizedBox(height: 40),

        // Multiple choice options area
        Container(
          key: _optionsAreaKey,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 20.0,
            runSpacing: 14.0,
            children:
                widget.exercise.options.isEmpty
                    ? []
                    : List.generate(widget.exercise.options.length, (index) {
                      final isSelected = selectedOption == index;

                      // If this option is selected, show placeholder, otherwise show the actual button
                      if (isSelected) {
                        final buttonSize = _buttonSizes[index];
                        return SizedBox(
                          width: buttonSize.width,
                          height: buttonSize.height,
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
                          key: _optionKeys[index],
                          padding: const EdgeInsets.symmetric(
                            vertical: _optionButtonVerticalPadding,
                            horizontal: _optionButtonHorizontalPadding,
                          ),
                          decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(12)),
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

        // Buttons
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
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    disabledBackgroundColor: Colors.grey[600],
                  ),
                  child: const LangText.body(hindi: 'जांचें', hinglish: 'Check'),
                ),
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _initialize();
    final orientation = MediaQuery.of(context).orientation;

    // Trigger calculations when orientation changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _calculateAndStoreButtonSizes();
        _calculateAndStoreBlankPosition();
      }
    });

    return ExerciseContainer(
      addTopPadding: false, // Custom padding needed for Stack
      child: VisibilityDetector(
        key: ValueKey(widget.exercise.id),
        onVisibilityChanged: (visibility) {
          if (visibility.visibleFraction != 1 || !mounted) return;
          _initialize();
        },
        child: Stack(
          key: _stackKey,
          children: [
            if (orientation == Orientation.landscape)
              // Landscape layout: Header at top, image left, content right
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Centered header with max width
                    Center(
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: _buildHeader()),
                    ),
                    const SizedBox(height: 20),
                    // Image and content side by side
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image on the left
                          Expanded(child: Center(child: _buildImage())),
                          const SizedBox(width: 20),
                          // Content on the right with max width constraint
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Group sentence and options together
                                  Column(
                                    children: [
                                      // Sentence with blank
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          if (_getSentenceParts()[0].isNotEmpty)
                                            LangText.bodyText(
                                              text: '${_getSentenceParts()[0]} ',
                                              style: const TextStyle(color: Colors.white, fontSize: 24),
                                            ),
                                          Container(
                                            key: _blankKey,
                                            constraints: BoxConstraints(minWidth: _widestOptionWidth),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: _blankHorizontalPadding,
                                              vertical: _blankVerticalPadding,
                                            ),
                                            decoration: const BoxDecoration(
                                              border: Border(bottom: BorderSide(color: Colors.orange, width: 3)),
                                            ),
                                            child: const SizedBox(height: 20),
                                          ),
                                          if (_getSentenceParts()[1].isNotEmpty)
                                            LangText.bodyText(
                                              text: ' ${_getSentenceParts()[1]}',
                                              style: const TextStyle(color: Colors.white, fontSize: 24),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 40),
                                      // Multiple choice options area
                                      Container(
                                        key: _optionsAreaKey,
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 20.0,
                                          runSpacing: 14.0,
                                          children:
                                              widget.exercise.options.isEmpty
                                                  ? []
                                                  : List.generate(widget.exercise.options.length, (index) {
                                                    final isSelected = selectedOption == index;

                                                    if (isSelected) {
                                                      final buttonSize = _buttonSizes[index];
                                                      return SizedBox(
                                                        width: buttonSize.width,
                                                        height: buttonSize.height,
                                                        key: _placeholderKeys[index],
                                                      );
                                                    }

                                                    return GestureDetector(
                                                      key: _placeholderKeys[index],
                                                      onTap: () {
                                                        if (selectedOption != null) {
                                                          setState(() {
                                                            selectedOption = null;
                                                            _isAnimating = false;
                                                          });

                                                          Future.delayed(const Duration(milliseconds: 100), () {
                                                            if (mounted) {
                                                              setState(() {
                                                                selectedOption = index;
                                                                _isAnimating = false;
                                                              });

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
                                                          setState(() {
                                                            selectedOption = index;
                                                            _isAnimating = false;
                                                          });

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
                                                        key: _optionKeys[index],
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
                                    ],
                                  ),
                                  const SizedBox(height: 60),
                                  // Buttons
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
                                        child: Container(
                                          width: double.infinity,
                                          constraints: const BoxConstraints(maxWidth: 240),
                                          child: ElevatedButton(
                                            onPressed: selectedOption != null ? _checkAnswer : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              // Portrait layout: Vertical stack with image height constraint
              Padding(
                padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    Container(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 3),
                      child: _buildImage(),
                    ),
                    const SizedBox(height: 32),
                    Expanded(child: _buildContent()),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

            // Animated positioned widget for selected option
            if (selectedOption != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                left: _isAnimating ? _getTargetPosition()['left'] : _getOriginalOptionPosition(selectedOption!)['left'],
                top: _isAnimating ? _getTargetPosition()['top'] : _getOriginalOptionPosition(selectedOption!)['top'],
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
    );
  }
}
