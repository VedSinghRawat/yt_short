import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/core/services/path_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:myapp/models/user/user.dart';

class DialogueList extends ConsumerStatefulWidget {
  final List<Dialogue> dialogues;
  final double itemHeight;

  const DialogueList({super.key, required this.dialogues, required this.itemHeight});

  @override
  ConsumerState<DialogueList> createState() => _DialogueListState();
}

class _DialogueListState extends ConsumerState<DialogueList> {
  late FixedExtentScrollController _scrollController;
  int _selectedDialogueIndex = 0;
  final _audioPlayer = AudioPlayer();

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

  // Keep track of dialogues to reset scroll if they change significantly
  List<Dialogue> _previousDialogues = [];

  @override
  void didUpdateWidget(covariant DialogueList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the list of dialogues changes (e.g., filtered), reset scroll position
    if (listEquals(widget.dialogues, _previousDialogues)) return;
    _previousDialogues = List.from(widget.dialogues); // Update previous list

    if (!_scrollController.hasClients) return;
    // Using a post-frame callback to ensure the scroll view has updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateToItem(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Update selected index immediately if needed
      if (_selectedDialogueIndex == 0) return;
      setState(() => _selectedDialogueIndex = 0);
    });
  }

  // Move audio playback logic here
  Future<void> _playDialogueAudio(String audioFilename) async {
    try {
      await _audioPlayer.stop();

      // Use ref to read the provider
      final filePath = PathService.dialogueAudioPath(audioFilename);

      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();
    } catch (e) {
      developer.log("Error playing dialogue audio: $e");
      // Optionally show an error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    // Store the current dialogues when building
    _previousDialogues = List.from(widget.dialogues);

    // Read user preference
    final prefLang = ref.watch(
      userControllerProvider.select((state) => state.currentUser?.prefLang ?? PrefLang.hinglish),
    );

    return ListWheelScrollView.useDelegate(
      // Use the state's scroll controller
      controller: _scrollController,
      itemExtent: widget.itemHeight,
      diameterRatio: 2.3,
      perspective: 0.004,
      physics: const FixedExtentScrollPhysics(),
      childDelegate: ListWheelChildListDelegate(
        children: List<Widget>.generate(
          // Use widget.dialogues
          widget.dialogues.length,
          (index) {
            final dialogue = widget.dialogues[index];
            final formattedTime = formatDurationMMSS(dialogue.time);
            // Use the state's selected index
            final bool isSelected = index == _selectedDialogueIndex;

            // Define styles based on selection state
            final double textFontSize = isSelected ? 20 : 18;
            final FontWeight textFontWeight = isSelected ? FontWeight.bold : FontWeight.w500;
            final double iconSize = isSelected ? 20 : 18;
            final Color timeColor = isSelected ? Colors.white : Colors.white70;
            final Color iconColor = isSelected ? Colors.white : Colors.white70;

            // Wrap the Center and Row with GestureDetector
            return GestureDetector(
              onTap: () async {
                // Call the local audio playback method
                await _playDialogueAudio(dialogue.audioFilename);
              },
              // Use a Container with transparent color for hit testing
              child: Container(
                color: Colors.transparent, // Ensures the empty space is tappable
                alignment: Alignment.center, // Center content within the tappable area
                child: Row(
                  // Restore Row layout
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center, // Center align the Row
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(formattedTime, style: TextStyle(fontSize: 12, color: timeColor)),
                    const SizedBox(width: 16), // Restore original spacing
                    // Wrap the Column with Padding for horizontal spacing
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                      ), // Add horizontal padding
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
                            textAlign: TextAlign.center, // Center align primary text
                          ),
                          // Conditional translation text
                          if (dialogue.hindiText.isNotEmpty && dialogue.hinglishText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0), // Smaller spacing
                              child: Text(
                                prefLang == PrefLang.hindi
                                    ? dialogue.hindiText
                                    : dialogue.hinglishText,
                                style: TextStyle(
                                  fontSize: textFontSize * 0.75, // Slightly smaller font size
                                  color: Colors.white70,
                                  fontWeight: FontWeight.normal,
                                ),
                                textAlign: TextAlign.center, // Center align translation text
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12), // Restore original spacing
                    // Keep the visual part
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 225 * 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 1),
                      ),
                      child: Icon(
                        // Apply conditional size/color
                        Icons.volume_up,
                        color: iconColor,
                        size: iconSize,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper function to compare lists (requires flutter/foundation.dart)
  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
