import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:just_audio/just_audio.dart'; // Import just_audio
import 'package:myapp/core/console.dart';
import 'package:myapp/core/services/level_service.dart'; // Import LevelService provider
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

// Convert to ConsumerStatefulWidget
class DialogueList extends ConsumerStatefulWidget {
  final List<Dialogue> dialogues;
  final double itemHeight;
  // Remove onPlayAudio parameter
  // final Function(String audioFilename) onPlayAudio;

  const DialogueList({
    super.key,
    required this.dialogues,
    required this.itemHeight,
    // required this.onPlayAudio, // Removed
  });

  @override
  ConsumerState<DialogueList> createState() => _DialogueListState();
}

class _DialogueListState extends ConsumerState<DialogueList> {
  // Change to ConsumerState
  late FixedExtentScrollController _scrollController;
  int _selectedDialogueIndex = 0;
  final _audioPlayer = AudioPlayer(); // Add AudioPlayer instance

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
    _audioPlayer.dispose(); // Dispose audio player
    super.dispose();
  }

  // Keep track of dialogues to reset scroll if they change significantly
  List<Dialogue> _previousDialogues = [];

  @override
  void didUpdateWidget(covariant DialogueList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the list of dialogues changes (e.g., filtered), reset scroll position
    if (!listEquals(widget.dialogues, _previousDialogues)) {
      _previousDialogues = List.from(widget.dialogues); // Update previous list
      if (_scrollController.hasClients) {
        // Using a post-frame callback to ensure the scroll view has updated
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            // Animate to the top if the list content changes
            _scrollController.animateToItem(0,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            // Update selected index immediately if needed
            if (_selectedDialogueIndex != 0) {
              setState(() {
                _selectedDialogueIndex = 0;
              });
            }
          }
        });
      }
    }
  }

  // Move audio playback logic here
  Future<void> _playDialogueAudio(String audioFilename) async {
    try {
      await _audioPlayer.stop();

      // Use ref to read the provider
      final levelService = ref.read(levelServiceProvider);
      final filePath = levelService.getDialogueAudioFilePath(audioFilename);
      developer.log("Attempting to play audio: $filePath");

      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();
      developer.log("Playing audio: $filePath");
    } catch (e) {
      developer.log("Error playing dialogue audio: $e");
      // Optionally show an error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    // Store the current dialogues when building
    _previousDialogues = List.from(widget.dialogues);

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
                Console.log("Tapped dialogue: ${dialogue.text}");
                // Call the local audio playback method
                await _playDialogueAudio(dialogue.audioFilename);
              },
              // Use a Container with transparent color for hit testing
              child: Container(
                color: Colors.transparent, // Ensures the empty space is tappable
                alignment: Alignment.center, // Center content within the tappable area
                child: Row(
                  // Keep Row for layout
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(fontSize: 12, color: timeColor), // Use conditional color
                    ),
                    const SizedBox(width: 16),
                    Text(
                      dialogue.text,
                      style: TextStyle(
                        // Apply conditional styles
                        fontSize: textFontSize,
                        color: Colors.white,
                        fontWeight: textFontWeight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 12),
                    // Keep the visual part
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
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
