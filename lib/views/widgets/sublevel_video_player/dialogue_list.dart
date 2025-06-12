import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/controllers/dialogue/dialogue_controller.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/models/user/user.dart';

class DialogueList extends ConsumerStatefulWidget {
  final List<SubDialogue> dialogues;
  final Function(double height)? onHeightCalculated;

  const DialogueList({super.key, required this.dialogues, this.onHeightCalculated});

  @override
  ConsumerState<DialogueList> createState() => _DialogueListState();
}

class _DialogueListState extends ConsumerState<DialogueList> {
  late FixedExtentScrollController _scrollController;
  int _selectedDialogueIndex = 0;
  final _audioPlayer = AudioPlayer();
  String _playingDialogueFilename = '';

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

  @override
  void didUpdateWidget(covariant DialogueList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_scrollController.hasClients || widget.dialogues.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateToItem(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

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
        if (mounted && _playingDialogueFilename == audioFilename) {
          setState(() => _playingDialogueFilename = ''); // Reset if file not found
        }
        return;
      }

      await _audioPlayer.setFilePath(filePath);

      // Update state immediately to show green icon
      if (mounted) {
        setState(() {
          _playingDialogueFilename = audioFilename;
        });
      }

      // Play and wait for completion or error
      await _audioPlayer
          .play()
          .then((_) {
            // When playback completes normally
            if (mounted && _playingDialogueFilename == audioFilename) {
              setState(() {
                _playingDialogueFilename = '';
              });
            }
          })
          .catchError((error) {
            // Handle errors during playback
            developer.log("Error during audio playback: $error");
            if (mounted && _playingDialogueFilename == audioFilename) {
              setState(() {
                _playingDialogueFilename = '';
              });
            }
          });
    } catch (e) {
      developer.log("Error setting up or playing dialogue audio: $e");
      // Ensure state is reset even if setup fails
      if (mounted && _playingDialogueFilename == audioFilename) {
        setState(() {
          _playingDialogueFilename = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dialogues.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onHeightCalculated?.call(0);
      });

      return const SizedBox.shrink();
    }

    final prefLang = ref.watch(
      userControllerProvider.select((state) => state.currentUser?.prefLang ?? PrefLang.hinglish),
    );

    final dialogueMap = ref.watch(dialogueControllerProvider.select((state) => state.dialogues));

    final dialogueByTime = Map.fromEntries(widget.dialogues.map((e) => MapEntry(e.time, dialogueMap[e.id]!)));

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate item height for full screen
        final double screenHeight = MediaQuery.of(context).size.height;
        final double calculatedItemHeight = screenHeight * 0.2; // 20% of screen height per item

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onHeightCalculated?.call(calculatedItemHeight);
        });

        return Stack(
          children: [
            ListWheelScrollView.useDelegate(
              controller: _scrollController,
              itemExtent: calculatedItemHeight,
              diameterRatio: 1.7,
              perspective: 0.004,
              physics: const FixedExtentScrollPhysics(),
              childDelegate: ListWheelChildListDelegate(
                children: List<Widget>.generate(dialogueByTime.length, (index) {
                  final el = dialogueByTime.entries.elementAt(index);
                  final dialogue = el.value;
                  final time = el.key;

                  final formattedTime = formatDurationMMSS(time);
                  final bool isSelected = index == _selectedDialogueIndex;

                  final double textFontSize = isSelected ? 22 : 18; // Reduced font sizes
                  final FontWeight textFontWeight = isSelected ? FontWeight.bold : FontWeight.w500;
                  final double iconSize = isSelected ? 24 : 20; // Reduced icon sizes
                  final Color timeColor = isSelected ? Colors.white : Colors.white70;
                  final isPlaying = _playingDialogueFilename == dialogue.id;
                  final Color iconColor =
                      isPlaying
                          ? Colors.green.shade400
                          : isSelected
                          ? Colors.white
                          : Colors.white70;

                  return Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(formattedTime, style: TextStyle(fontSize: 16, color: timeColor)),
                        const SizedBox(width: 24),
                        Flexible(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),

                                child: SizedBox(
                                  width: constraints.maxWidth * 0.8,
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
                                      if (dialogue.hindiText.isNotEmpty && dialogue.hinglishText.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            prefLang == PrefLang.hindi ? dialogue.hindiText : dialogue.hinglishText,
                                            style: TextStyle(
                                              fontSize: textFontSize * 0.8,
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
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _playDialogueAudio(dialogue.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: isPlaying ? Colors.white : Colors.white.withAlpha(50),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isPlaying ? Colors.green.shade100 : Colors.white70,
                                width: isPlaying ? 2 : 1.5,
                              ),
                            ),
                            transform: Matrix4.identity()..scale(isPlaying ? 1.2 : 1.0),
                            transformAlignment: Alignment.center,
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
