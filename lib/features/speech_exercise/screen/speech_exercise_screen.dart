import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/widgets/yt_player.dart';
import 'package:myapp/features/speech_exercise/widgets/speech_exercise_card.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';

class SpeechExerciseScreen extends ConsumerStatefulWidget {
  final SpeechExercise exercise;
  final Function(YoutubePlayerController)? onControllerInitialized;
  final String? uniqueId;

  const SpeechExerciseScreen({
    super.key,
    this.onControllerInitialized,
    required this.exercise,
    this.uniqueId,
  });

  @override
  ConsumerState<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends ConsumerState<SpeechExerciseScreen> {
  YoutubePlayerController? _controller;
  bool _hasShownDialog = false;
  bool _isDisposed = false;
  bool _isCheckingPauseTime = false;

  void _onControllerInitialized(YoutubePlayerController controller) {
    if (_isDisposed) return;

    _controller = controller;

    // Set up controller listener for player state changes
    controller.listen((event) {
      if (_isDisposed || !mounted) return;

      // Only check for pause time when the video is playing
      if (!_hasShownDialog && event.playerState == PlayerState.playing) {
        _checkVideoPauseTime();
      }
    });
  }

  // Check current video position to determine if we should pause
  Future<void> _checkVideoPauseTime() async {
    if (_isDisposed || !mounted || _hasShownDialog || _isCheckingPauseTime) return;

    // Prevent multiple simultaneous checks
    _isCheckingPauseTime = true;

    try {
      // Get the current video time in seconds
      final position = await _controller!.currentTime;

      // Check if we've reached the pause point
      if (position >= widget.exercise.pauseAt) {
        _controller!.pauseVideo();
        _hasShownDialog = true;
        _showExerciseDialog();
      }
    } catch (e) {
      // Silently handle any errors
    } finally {
      _isCheckingPauseTime = false;
    }
  }

  Future<void> _showExerciseDialog() async {
    if (_isDisposed || !mounted) return;

    final isAdmin = ref.read(userControllerProvider).currentUser?.isAdmin ?? false;

    showDialog(
      context: context,
      barrierDismissible: isAdmin || kDebugMode,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.9),
      builder: (context) => PopScope(
        canPop: isAdmin || kDebugMode,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            vertical: 48,
            horizontal: 24,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.75),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(255, 255, 255, 0.2),
                  blurRadius: 12.0,
                  spreadRadius: 4.0,
                ),
              ],
            ),
            child: SpeechExerciseCard(
              text: widget.exercise.text,
              onContinue: () {
                setState(() {
                  _controller?.playVideo();
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YtPlayer(
      key: Key('${widget.exercise.level}-${widget.exercise.subLevel}-${widget.exercise.ytId}'),
      videoId: widget.exercise.ytId,
      uniqueId: widget.uniqueId,
      onControllerInitialized: _onControllerInitialized,
    );
  }
}
