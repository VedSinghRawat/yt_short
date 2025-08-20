import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/dialogue/dialogue_controller.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/models/video/video.dart';
import 'package:myapp/models/dialogues/dialogues.dart';
import 'package:myapp/services/audio/audio_service.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/services/responsiveness/responsiveness_service.dart';
import 'package:myapp/views/widgets/lang_text.dart';

class DialogueList extends ConsumerStatefulWidget {
  final List<VideoDialogue> dialogues;

  const DialogueList({super.key, required this.dialogues});

  @override
  ConsumerState<DialogueList> createState() => _DialogueListState();
}

class _DialogueListState extends ConsumerState<DialogueList> {
  late FixedExtentScrollController _scrollController;
  int _selectedDialogueIndex = 0;
  final AudioService _audioService = AudioService();
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
      // If same audio is playing, stop it
      if (_playingDialogueFilename == audioFilename && _audioService.isPlaying) {
        await _audioService.stopAudio();
        setState(() {
          _playingDialogueFilename = '';
        });
        return;
      }

      // Update state immediately to show green icon
      setState(() {
        _playingDialogueFilename = audioFilename;
      });

      final localAudioFilePath = PathService.dialogueAsset(audioFilename, AssetType.audio);
      final audioFile = FileService.getFile(localAudioFilePath);

      await _audioService.playAudio(
        audioPath: audioFile.path,
        onFinished: () {
          if (mounted && _playingDialogueFilename == audioFilename) {
            setState(() {
              _playingDialogueFilename = '';
            });
          }
        },
      );
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
      return const SizedBox.shrink();
    }

    ref.watch(langControllerProvider); // Watch for language changes

    final dialogueMap = ref.watch(dialogueControllerProvider.select((state) => state.dialogues));

    final dialogues =
        widget.dialogues.map((e) => dialogueMap[e.id]).where((dialogue) => dialogue != null).cast<Dialogue>().toList();

    final responsiveness = ResponsivenessService(context);
    final isTablet = responsiveness.screenType != Screen.mobile;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate item height for full screen
        final double screenHeight = MediaQuery.of(context).size.height;
        final double calculatedItemHeight = screenHeight * 0.25;

        return Stack(
          children: [
            // Main list with scrollbar
            Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              interactive: true,
              thickness: 6.0,
              radius: const Radius.circular(3.0),
              child: ListWheelScrollView.useDelegate(
                controller: _scrollController,
                itemExtent: calculatedItemHeight,
                diameterRatio: 2.0,
                perspective: 0.002,
                physics: const FixedExtentScrollPhysics(),
                childDelegate: ListWheelChildListDelegate(
                  children:
                      dialogues.map((dialogue) {
                        final bool isSelected = dialogue.id == widget.dialogues[_selectedDialogueIndex].id;

                        // Responsive font sizes for tablets
                        final double baseFontSize = isTablet ? 28 : 22; // Increased for tablets
                        final double textFontSize = isSelected ? baseFontSize : (isTablet ? 22 : 18);
                        final FontWeight textFontWeight = isSelected ? FontWeight.bold : FontWeight.w500;
                        final double iconSize = isSelected ? (isTablet ? 28 : 24) : (isTablet ? 24 : 20);
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
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    LangText.bodyText(
                                      text: dialogue.text,
                                      style: TextStyle(
                                        fontSize: textFontSize,
                                        color: Colors.white,
                                        fontWeight: textFontWeight,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: LangText.body(
                                        hindi: dialogue.hindiText,
                                        hinglish: dialogue.hinglishText,
                                        style: TextStyle(fontSize: textFontSize * 0.8, color: Colors.white70),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

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
                      }).toList(),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 20, // Leave space for scrollbar
              child: IgnorePointer(
                child: Container(
                  height: calculatedItemHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.black.withAlpha(5)],
                      stops: const [0.0, 0.9],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 20, // Leave space for scrollbar
              child: IgnorePointer(
                child: Container(
                  height: calculatedItemHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.black.withAlpha(5)],
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
