import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/core/widgets/sublevel_video_player/sublevel_video_player.dart';
import 'package:myapp/features/speech_exercise/providers/speech_provider.dart';
import 'package:myapp/features/speech_exercise/widgets/exercise_sentence_card.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:video_player/video_player.dart';

class SpeechExerciseScreen extends ConsumerStatefulWidget {
  final SpeechExercise exercise;
  final String? uniqueId;
  final String? videoLocalPath;
  final List<String>? videoUrls;
  final VoidCallback? goToNext;

  const SpeechExerciseScreen({
    super.key,
    required this.exercise,
    this.videoLocalPath,
    this.videoUrls,
    this.uniqueId,
    this.goToNext,
  });

  @override
  ConsumerState<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends ConsumerState<SpeechExerciseScreen> {
  VideoPlayerController? _exerciseController;
  bool _hasShownDialog = false;
  bool _isDialogOpen = false;
  Function(bool)? _setIsSeeking;

  void _onControllerInitialized(VideoPlayerController controller, Function(bool) setIsSeeking) {
    if (!mounted) return;

    _exerciseController?.removeListener(_exerciseListener);

    setState(() {
      _exerciseController = controller;
      _setIsSeeking = setIsSeeking;
    });
    _exerciseController!.addListener(_exerciseListener);
  }

  void _exerciseListener() {
    if (!mounted || _exerciseController == null || !_exerciseController!.value.isInitialized) {
      return;
    }

    final position = _exerciseController!.value.position;
    final isPlaying = _exerciseController!.value.isPlaying;

    if (!_hasShownDialog && isPlaying && position.inSeconds >= widget.exercise.pauseAt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasShownDialog) {
          _showTestSentenceDialog();
        }
      });
    }
  }

  Future<void> _onClose() async {
    setState(() {
      _isDialogOpen = false;
    });

    final localProgress = SharedPref.get(PrefKey.currProgress());

    final isMaxLevel = isLevelAfter(
      localProgress?.maxLevel ?? 0,
      localProgress?.maxSubLevel ?? 0,
      widget.exercise.level,
      widget.exercise.index,
    );

    final isAdmin = ref.read(userControllerProvider).currentUser?.isAdmin ?? false;
    final isPassed = ref.read(speechProvider.notifier).isPassed;

    if (isAdmin || isMaxLevel || isPassed) {
      setState(() {
        _hasShownDialog = true;
      });
      return;
    }

    _setIsSeeking?.call(true);
    await _exerciseController?.seekTo(Duration.zero);
    await _exerciseController?.play();
    _setIsSeeking?.call(false);
    ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(false);
  }

  void _showTestSentenceDialog() {
    _exerciseController?.pause();

    if (!mounted) return;

    setState(() {
      _isDialogOpen = true;
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.9),
      builder:
          (context) => PopScope(
            canPop: true,
            onPopInvokedWithResult: (bool result, bool? didPop) async {
              if (_hasShownDialog) return;

              await _onClose();
            },
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: SpeechExerciseCard(
                levelId: widget.exercise.levelId,
                audioFilename: widget.exercise.audioFilename,
                text: widget.exercise.text,
                onClose: () async {
                  await _onClose();
                  if (mounted) context.pop();
                },
                onContinue: () {
                  if (mounted) {
                    setState(() {
                      _hasShownDialog = true;
                    });
                    _exerciseController?.play();
                    context.pop();
                    widget.goToNext?.call();
                  }
                },
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SublevelVideoPlayer(
      key: Key(widget.uniqueId ?? widget.videoLocalPath ?? widget.exercise.videoFilename),
      videoLocalPath: widget.videoLocalPath,
      videoUrls: widget.videoUrls,
      uniqueId: widget.uniqueId,
      onControllerInitialized: _onControllerInitialized,
      dialogues: widget.exercise.dialogues,
      stayPause: _isDialogOpen,
    );
  }
}
