import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/models/arrange_exercise/arrange_exercise.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/views/widgets/sublevel_image.dart';
import 'package:myapp/views/widgets/lang_text.dart';
import 'package:myapp/views/widgets/exercise_container.dart';
import 'package:reorderables/reorderables.dart';

class ArrangeExerciseScreen extends ConsumerStatefulWidget {
  final ArrangeExercise exercise;
  final VoidCallback goToNext;
  final bool isCurrent;

  const ArrangeExerciseScreen({super.key, required this.exercise, required this.goToNext, required this.isCurrent});

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

    if (oldWidget.isCurrent && !widget.isCurrent) {
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

    final canBeDifferent = currentOrder.toSet().length > 1;

    if (canBeDifferent) {
      do {
        currentOrder.shuffle();
      } while (currentOrder.join(' ') == originalWords.join(' '));
    } else {
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

    if (userAnswer == correctAnswer) {
      setState(() {
        _isCorrect = true;
      });
    } else {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LangText.body(
            hindi: 'आपके वाक्य में कुछ गलत है, फिर से कोशिश करें',
            hinglish: 'Aapke sentence mein kuch galat hai, firse koshish kare',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
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

      final audioPath = PathService.sublevelAsset(widget.exercise.levelId, widget.exercise.id, AssetType.audio);
      final audioFile = FileService.getFile(audioPath);

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
      key: ValueKey(word),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: LangText.bodyText(text: word, style: const TextStyle(color: Colors.black, fontSize: 18)),
    );
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
            hindi: 'वाक्य व्यवस्था',
            hinglish: 'Arrange Exercise',
            style: TextStyle(color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(height: 8),
          LangText.body(
            hindi: 'नीचे दिए गए शब्दों को खींच कर छवि के हिसाब से सही वाक्य बनाएं।',
            hinglish: 'Niche diye gye words ko kheench kar image ke hisaab se sahi vakya banaye.',
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

  Widget _buildArrangeContainer() {
    return Container(
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
        needsLongPressDraggable: false,
        onReorder: _onReorder,
        children: currentOrder.map((word) => _buildWordBlock(word)).toList(),
      ),
    );
  }

  Widget _buildButtons() {
    final theme = Theme.of(context);

    if (_isCorrect) {
      return Padding(
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
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _checkAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            child: const LangText.body(hindi: 'जांचें', hinglish: 'Check'),
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
              label: LangText.body(
                hindi: _isPlayingAudio ? 'ध्वनि चल रही है' : 'सुझाव',
                hinglish: _isPlayingAudio ? 'Playing' : 'Hint',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isPlayingAudio ? theme.colorScheme.secondary : theme.colorScheme.secondary.withValues(alpha: 0.2),
                foregroundColor: _isPlayingAudio ? theme.colorScheme.onSecondary : theme.colorScheme.onSurface,
                side:
                    _isPlayingAudio
                        ? null
                        : BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.5), width: 1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExerciseContainer(
      maxWidth: null, // No max width for arrange exercise to allow full width in landscape
      child: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            // Landscape layout: Header at top (centered with max width), then image left and content right
            return Column(
              children: [
                // Centered header with max width
                Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: _buildHeader())),
                const SizedBox(height: 20),
                // Image and content side by side
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Image on the left - no constraints, maintains aspect ratio
                      Expanded(child: Center(child: _buildImage())),
                      const SizedBox(width: 20),
                      // Arrange container and buttons on the right with max width constraint
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [_buildArrangeContainer(), const SizedBox(height: 80), _buildButtons()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Portrait layout: Vertical stack
            return Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 3),
                  child: _buildImage(),
                ),
                const SizedBox(height: 20),
                _buildArrangeContainer(),
                const Spacer(),
                _buildButtons(),
              ],
            );
          }
        },
      ),
    );
  }
}
