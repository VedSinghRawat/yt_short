import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/models/arrange_exercise/arrange_exercise.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';

class ArrangeExerciseScreen extends ConsumerStatefulWidget {
  final ArrangeExercise exercise;
  final VoidCallback goToNext;

  const ArrangeExerciseScreen({super.key, required this.exercise, required this.goToNext});

  @override
  ConsumerState<ArrangeExerciseScreen> createState() => _ArrangeExerciseScreenState();
}

class _ArrangeExerciseScreenState extends ConsumerState<ArrangeExerciseScreen> {
  List<String> currentOrder = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.exercise.text.trim().toLowerCase().split(' ');
    currentOrder.shuffle();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final String word = currentOrder.removeAt(oldIndex);

      // If dropping at the end position, insert at the end
      if (newIndex >= currentOrder.length) {
        currentOrder.add(word);
      } else {
        // Adjust index if needed for standard reordering
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        currentOrder.insert(newIndex, word);
      }
    });
  }

  void _checkAnswer() {
    final userAnswer = currentOrder.join(' ').toLowerCase().trim();
    final correctAnswer = widget.exercise.text.toLowerCase().trim();
    final langController = ref.read(langControllerProvider.notifier);

    if (userAnswer == correctAnswer) {
      // Correct answer - proceed to next
      widget.goToNext();
    } else {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            langController.choose(
              hindi: 'आपके वाक्य में कुछ ग़लत है, फिर से कोशिश करें',
              hinglish: 'Aapke sentence mein kuch galat hai, firse koshish kare',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _playHint() async {
    final langController = ref.read(langControllerProvider.notifier);

    try {
      // Stop current audio if playing
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
        setState(() {
          _isPlayingAudio = false;
        });
        return;
      }

      // Get the audio file path
      final audioPath = PathService.sublevelAsset(widget.exercise.levelId, widget.exercise.id, AssetType.audio);
      final audioFile = FileService.getFile(audioPath);

      // Check if audio file exists
      if (await audioFile.exists()) {
        // Set the audio file path and play
        await _audioPlayer.setFilePath(audioFile.path);

        setState(() {
          _isPlayingAudio = true;
        });

        // Play the audio and wait for completion
        await _audioPlayer
            .play()
            .then((_) {
              if (mounted) {
                setState(() {
                  _isPlayingAudio = false;
                });
              }
            })
            .catchError((error) {
              developer.log("Error during audio playback: $error");
              if (mounted) {
                setState(() {
                  _isPlayingAudio = false;
                });
                // Show fallback text hint
                _showTextHint(langController);
              }
            });
      } else {
        // Audio file doesn't exist, show text hint
        developer.log("Audio file not found: $audioPath");
        _showTextHint(langController);
      }
    } catch (e) {
      developer.log("Error setting up audio playback: $e");
      // Fallback to showing text hint if audio fails
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
        _showTextHint(langController);
      }
    }
  }

  void _showTextHint(dynamic langController) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          langController.choose(hindi: 'सुझाव: "${widget.exercise.text}"', hinglish: 'Hint: "${widget.exercise.text}"'),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = PathService.sublevelAsset(widget.exercise.levelId, widget.exercise.id, AssetType.image);
    final theme = Theme.of(context);
    final langController = ref.read(langControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
          child: Column(
            children: [
              // Header with title and instructions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text(
                      langController.choose(hindi: 'वाक्य व्यवस्था', hinglish: 'Arrange Exercise'),
                      style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      langController.choose(
                        hindi: 'नीचे दिए गए शब्दों को खींच कर छवि के हिसाब से सही वाक्य बनाएं।',
                        hinglish: 'Niche diye gye words ko kheech kar image ke hisaab se sahi vakya banaye.',
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

              // Image with fixed height (30% of screen)
              Container(
                height: MediaQuery.of(context).size.height * 0.3, // 30% of screen height
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[800]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    FileService.getFile(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      developer.log('error is $error, $imagePath');
                      return Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[800]),
                        child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Text above word container

              // Reorderable word container (size based on content)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!, width: 2),
                ),
                child: ReorderableWrap(spacing: 8, runSpacing: 8, onReorder: _onReorder, words: currentOrder),
              ),

              const Spacer(), // Push buttons to bottom
              // Action buttons
              Row(
                children: [
                  // Check button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _checkAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      child: Text(langController.choose(hindi: 'जांचें', hinglish: 'Check')),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Hint button
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(_isPlayingAudio ? 1.05 : 1.0),
                      child: OutlinedButton.icon(
                        onPressed: _playHint,
                        icon: Icon(_isPlayingAudio ? Icons.stop : Icons.volume_up),
                        label: Text(
                          _isPlayingAudio
                              ? langController.choose(hindi: 'बज रहा है', hinglish: 'Playing')
                              : langController.choose(hindi: 'सुझाव', hinglish: 'Hint'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _isPlayingAudio ? Colors.green : theme.colorScheme.primary,
                          backgroundColor: _isPlayingAudio ? Colors.white : null,
                          side: BorderSide(color: _isPlayingAudio ? Colors.green : theme.colorScheme.primary, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom ReorderableWrap widget since Flutter doesn't have one built-in
class ReorderableWrap extends StatelessWidget {
  final List<String> words;
  final Function(int, int) onReorder;
  final double spacing;
  final double runSpacing;

  const ReorderableWrap({
    super.key,
    required this.words,
    required this.onReorder,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
  });

  Widget _buildWordBlock(String word, {bool isPlaceholder = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPlaceholder ? Colors.grey[500]!.withValues(alpha: 0.5) : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        border: isPlaceholder ? Border.all(color: Colors.grey[400]!, width: 1, style: BorderStyle.solid) : null,
        boxShadow:
            isPlaceholder
                ? null
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Text(
        word,
        style: TextStyle(
          color: isPlaceholder ? Colors.grey[600] : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    // Add all word widgets
    children.addAll(
      words.asMap().entries.map((entry) {
        int index = entry.key;
        String word = entry.value;

        return Draggable<DragData>(
          data: DragData(index: index, word: word),
          feedback: Transform.scale(
            scale: 1.1,
            child: Material(elevation: 8, borderRadius: BorderRadius.circular(8), child: _buildWordBlock(word)),
          ),
          childWhenDragging: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[600]!, width: 1),
            ),
            child: Text(word, style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w300)),
          ),
          child: DragTarget<DragData>(
            onAcceptWithDetails: (details) {
              if (details.data.index != index) {
                onReorder(details.data.index, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              // Show placeholder of the dragged word at drop position
              if (candidateData.isNotEmpty) {
                final draggedWord = candidateData.first!.word;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWordBlock(draggedWord, isPlaceholder: true),
                    const SizedBox(width: 8),
                    _buildWordBlock(word),
                  ],
                );
              }
              return _buildWordBlock(word);
            },
          ),
        );
      }),
    );

    // Add a drop target at the end for last position
    children.add(
      DragTarget<DragData>(
        onAcceptWithDetails: (details) {
          // Move to last position (words.length would be the new last index)
          onReorder(details.data.index, words.length);
        },
        builder: (context, candidateData, rejectedData) {
          if (candidateData.isNotEmpty) {
            final draggedWord = candidateData.first!.word;
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _buildWordBlock(draggedWord, isPlaceholder: true),
            );
          }
          // Invisible drop zone when not dragging
          return const SizedBox(width: 20, height: 44);
        },
      ),
    );

    return Wrap(spacing: spacing, runSpacing: runSpacing, children: children);
  }
}

// Data class for drag and drop
class DragData {
  final int index;
  final String word;

  DragData({required this.index, required this.word});
}
