import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/models/arrange_exercise/arrange_exercise.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:reorderables/reorderables.dart';

class ArrangeExerciseScreen extends ConsumerStatefulWidget {
  final ArrangeExercise exercise;
  final VoidCallback goToNext;
  final bool isVisible;

  const ArrangeExerciseScreen({super.key, required this.exercise, required this.goToNext, required this.isVisible});

  @override
  ConsumerState<ArrangeExerciseScreen> createState() => _ArrangeExerciseScreenState();
}

class _ArrangeExerciseScreenState extends ConsumerState<ArrangeExerciseScreen> {
  List<String> currentOrder = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _initializeAndShuffleWords();

    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;

      final shouldStop =
          state.processingState == ProcessingState.completed ||
          state.processingState == ProcessingState.idle ||
          !state.playing;

      if (!(shouldStop && _isPlayingAudio)) return;

      setState(() {
        _isPlayingAudio = false;
      });
    });
  }

  @override
  void didUpdateWidget(ArrangeExerciseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if isVisible changed from true to false (user scrolled away)
    if (oldWidget.isVisible && !widget.isVisible) {
      // Reset all user interactions
      setState(() {
        _initializeAndShuffleWords();
        _isCorrect = false;
      });

      // Stop any playing audio
      if (_isPlayingAudio) {
        _audioPlayer.stop();
        setState(() {
          _isPlayingAudio = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeAndShuffleWords() {
    final originalWords = widget.exercise.text.trim().toLowerCase().split(' ');
    currentOrder = List.from(originalWords);

    // Only shuffle if there are multiple unique words to avoid infinite loops
    final canBeDifferent = currentOrder.toSet().length > 1;

    if (canBeDifferent) {
      do {
        currentOrder.shuffle();
      } while (currentOrder.join(' ') == originalWords.join(' '));
    } else {
      // For single-word sentences or sentences with all same words (e.g., "a a a"),
      // shuffling won't produce a different order.
      currentOrder.shuffle();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final String word = currentOrder.removeAt(oldIndex);
      currentOrder.insert(newIndex, word);
    });
  }

  void _checkAnswer() {
    final userAnswer = currentOrder.join(' ').toLowerCase().trim();
    final correctAnswer = widget.exercise.text.toLowerCase().trim();
    final langController = ref.read(langControllerProvider.notifier);

    if (userAnswer == correctAnswer) {
      setState(() {
        _isCorrect = true;
      });
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
    try {
      // Stop current audio if playing
      if (_isPlayingAudio) {
        await _audioPlayer.stop();
        setState(() {
          _isPlayingAudio = false;
        });
        return;
      }

      // Get the audio file path
      final audioPath = PathService.sublevelAsset(widget.exercise.levelId, widget.exercise.id, AssetType.audio);
      final audioFile = FileService.getFile(audioPath);

      // Set the audio file path and play
      await _audioPlayer.setFilePath(audioFile.path);

      setState(() {
        _isPlayingAudio = true;
      });

      await _audioPlayer.play();
    } catch (e) {
      developer.log("Error setting up audio playback: $e");
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
    }
  }

  Widget _buildWordBlock(String word) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Text(word, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(langControllerProvider); // Watch for language changes
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
                      ref
                          .read(langControllerProvider.notifier)
                          .choose(hindi: 'वाक्य व्यवस्था', hinglish: 'Arrange Exercise'),
                      style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      langController.choose(
                        hindi: 'नीचे दिए गए शब्दों को खींच कर छवि के हिसाब से सही वाक्य बनाएं।',
                        hinglish: 'Niche diye gye words ko kheech kar image ke hisaab se sahi vakya banaye.',
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withOpacity(0.9),
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

              // Reorderable word container (size based on content)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!, width: 2),
                ),
                child: ReorderableWrap(
                  spacing: 6,
                  runSpacing: 12,
                  onReorder: _onReorder,
                  children: currentOrder.map((word) => _buildWordBlock(word)).toList(),
                ),
              ),

              const Spacer(), // Push buttons to bottom

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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        child: Text(langController.choose(hindi: 'आगे बढ़ें', hinglish: 'Continue')),
                      ),
                    ),
                  )
                  : Row(
                    children: [
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

                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform: Matrix4.identity()..scale(_isPlayingAudio ? 1.05 : 1.0),
                          child: ElevatedButton.icon(
                            onPressed: _playHint,
                            icon: Icon(_isPlayingAudio ? Icons.stop : Icons.volume_up),
                            label: Text(
                              _isPlayingAudio
                                  ? langController.choose(hindi: 'बज रहा है', hinglish: 'Playing')
                                  : langController.choose(hindi: 'सुझाव', hinglish: 'Hint'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isPlayingAudio
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.secondary.withOpacity(0.2),
                              foregroundColor:
                                  _isPlayingAudio ? theme.colorScheme.onSecondary : theme.colorScheme.onSurface,
                              side:
                                  _isPlayingAudio
                                      ? null
                                      : BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5), width: 1),
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
