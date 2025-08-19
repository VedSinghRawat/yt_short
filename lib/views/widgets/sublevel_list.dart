import 'dart:developer' as developer;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/views/widgets/loader.dart';
import 'package:myapp/views/widgets/lang_text.dart';
import 'package:myapp/views/widgets/video_player/video_player_screen.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:myapp/views/screens/error_screen.dart';
import 'package:myapp/views/screens/speech_exercise_screen.dart';
import 'package:myapp/views/screens/arrange_exercise_screen.dart';
import 'package:myapp/views/screens/fill_exercise_screen.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:myapp/models/video/video.dart';

class SublevelsList extends ConsumerStatefulWidget {
  final List<SubLevel> sublevels;
  final Map<String, bool> loadingById;
  final Future<void> Function(int index, PageController controller)? onSublevelChange;

  const SublevelsList({super.key, required this.sublevels, this.onSublevelChange, required this.loadingById});

  @override
  ConsumerState<SublevelsList> createState() => _SublevelsListState();
}

const bufferSize = 1001;
const middleIndex = 500;

class _SublevelsListState extends ConsumerState<SublevelsList> {
  late PageController _pageController;
  final List<SubLevel?> _sublevelBuffer = List.filled(bufferSize, null, growable: false);
  int _currentPageIndex = 0;
  bool _isLoadingPreviousLevels = false;
  bool _isScrollBackBlocked = false;

  int _getMaxForwardScrollableIndex() {
    int lastNonNullIndex = -1;
    for (int i = 0; i < bufferSize; i++) {
      if (_sublevelBuffer[i] != null) {
        lastNonNullIndex = i;
      }
    }

    // If nothing is loaded, restrict to 0
    if (lastNonNullIndex == -1) return 0;

    final candidate = lastNonNullIndex + 1;
    return candidate >= bufferSize ? bufferSize - 1 : candidate;
  }

  /// Returns the expected sublevel for a given buffer index, even if buffer holds null there.
  /// Uses nearest non-null anchor in buffer and a sorted copy of `widget.sublevels` to infer.
  SubLevel? _expectedSublevelAt(int bufferIndex) {
    if (bufferIndex < 0 || bufferIndex >= bufferSize || widget.sublevels.isEmpty) return null;

    int? anchorBufferIndex;
    SubLevel? anchorSublevel;
    // Prefer exact non-null at index
    if (_sublevelBuffer[bufferIndex] != null) {
      anchorBufferIndex = bufferIndex;
      anchorSublevel = _sublevelBuffer[bufferIndex];
    } else {
      // Find nearest non-null around index
      for (int offset = 1; offset < bufferSize; offset++) {
        final left = bufferIndex - offset;
        if (left >= 0 && _sublevelBuffer[left] != null) {
          anchorBufferIndex = left;
          anchorSublevel = _sublevelBuffer[left];
          break;
        }
        final right = bufferIndex + offset;
        if (right < bufferSize && _sublevelBuffer[right] != null) {
          anchorBufferIndex = right;
          anchorSublevel = _sublevelBuffer[right];
          break;
        }
        if (left < 0 && right >= bufferSize) break;
      }
    }

    if (anchorBufferIndex == null || anchorSublevel == null) return null;

    // Build sorted list once per call
    final sortedSublevels = List<SubLevel>.from(widget.sublevels)..sort((a, b) {
      if (isLevelAfter(a.level, a.index, b.level, b.index)) return 1;
      if (isLevelEqual(a.level, a.index, b.level, b.index)) return 0;
      return -1;
    });

    final anchorListIndex = sortedSublevels.indexWhere(
      (s) => s.levelId == anchorSublevel!.levelId && s.level == anchorSublevel.level && s.index == anchorSublevel.index,
    );
    if (anchorListIndex == -1) return null;

    final delta = bufferIndex - anchorBufferIndex;
    final targetListIndex = anchorListIndex + delta;
    if (targetListIndex < 0 || targetListIndex >= sortedSublevels.length) return null;

    return sortedSublevels[targetListIndex];
  }

  /// Checks if we can scroll back further from the current position
  bool _canScrollBack(int currentIndex) {
    // Check if we have any sublevels before the current position
    for (int i = currentIndex - 1; i >= 0; i--) {
      if (_sublevelBuffer[i] != null) {
        return true;
      }
    }
    return false;
  }

  /// Checks if we're at the first level (level 1, sublevel 1)
  bool _isAtFirstLevel(int currentIndex) {
    final currentSublevel = _sublevelBuffer[currentIndex];
    if (currentSublevel != null) {
      return currentSublevel.level == 1 && currentSublevel.index == 1;
    }
    return false;
  }

  /// Fetches previous levels when needed for scrolling back
  Future<void> _fetchPreviousLevelsIfNeeded() async {
    developer.log('🔄 Starting _fetchPreviousLevelsIfNeeded()');

    if (_isLoadingPreviousLevels) {
      developer.log('⏳ Already loading previous levels, skipping...');
      return;
    }

    final levelState = ref.read(levelControllerProvider);
    final orderedIds = levelState.orderedIds;

    if (orderedIds == null || orderedIds.isEmpty) {
      developer.log('⚠️ No ordered IDs available, cannot fetch previous levels');
      return;
    }

    developer.log('📊 Total ordered level IDs: ${orderedIds.length}');

    // Find the first loaded level ID from the buffer
    String? firstLoadedLevelId;
    for (int i = 0; i < bufferSize; i++) {
      if (_sublevelBuffer[i] != null) {
        firstLoadedLevelId = _sublevelBuffer[i]!.levelId;
        developer.log('🎯 First loaded level ID found: $firstLoadedLevelId at buffer position $i');
        break;
      }
    }

    if (firstLoadedLevelId == null) {
      developer.log('⚠️ No loaded levels found in buffer');
      return;
    }

    final firstLoadedIndex = orderedIds.indexOf(firstLoadedLevelId);
    developer.log('📍 First loaded level position in ordered IDs: $firstLoadedIndex');

    // If we're at the first level in orderedIds, we can't fetch more
    if (firstLoadedIndex <= 0) {
      developer.log('ℹ️ Already at first level, no previous levels to fetch');
      return;
    }

    // Check if we need to fetch previous levels
    final needsPreviousLevels = firstLoadedIndex > 0;

    if (needsPreviousLevels) {
      developer.log('📥 Need to fetch previous levels, starting fetch...');
      setState(() {
        _isLoadingPreviousLevels = true;
      });

      try {
        final levelController = ref.read(levelControllerProvider.notifier);

        // Fetch the previous level
        final previousLevelId = orderedIds[firstLoadedIndex - 1];
        developer.log('📥 Fetching previous level: $previousLevelId');
        await levelController.getLevel(previousLevelId);

        // Update the buffer after fetching
        developer.log('🔄 Updating buffer after fetching previous level...');
        _updateBuffer();

        if (mounted) {
          showSnackBar(
            context,
            message: choose(
              hindi: 'पिछले लेवल लोड हो गए हैं',
              hinglish: 'Pichle levels load ho gaye hain',
              lang: ref.read(langControllerProvider),
            ),
            type: SnackBarType.success,
          );
        }
        developer.log('✅ Previous level fetched and buffer updated successfully');
      } catch (e) {
        developer.log('❌ Error fetching previous level: $e');
        if (mounted) {
          showSnackBar(
            context,
            message: choose(
              hindi: 'पिछले लेवल लोड करने में समस्या हुई',
              hinglish: 'Pichle levels load karne mein problem hui',
              lang: ref.read(langControllerProvider),
            ),
            type: SnackBarType.error,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingPreviousLevels = false;
          });
          developer.log('🔄 Loading state reset');
        }
      }
    }
    developer.log('✅ _fetchPreviousLevelsIfNeeded() completed');
  }

  /// Page controller listener to handle scroll back prevention
  void _onPageControllerUpdate() {
    if (!mounted) return;

    final currentPage = _pageController.page ?? _currentPageIndex;
    final isScrollingBack = currentPage < _currentPageIndex;
    final isScrollingForward = currentPage > _currentPageIndex;

    if (isScrollingBack) {
      // If at the first sublevel of the current level, gate back-scroll based on previous level load state
      final currentSublevel = _getCurrentSublevel(_currentPageIndex);
      if (currentSublevel != null && currentSublevel.index == 1) {
        final levelState = ref.read(levelControllerProvider);
        final orderedIds = levelState.orderedIds;
        if (orderedIds != null && orderedIds.isNotEmpty) {
          final currentLevelIdx = orderedIds.indexOf(currentSublevel.levelId);
          if (currentLevelIdx > 0) {
            final prevLevelId = orderedIds[currentLevelIdx - 1];
            final loadingStatus = levelState.loadingById[prevLevelId];

            // If previous level is not loaded yet (null or loading), block back scroll
            if (loadingStatus == null) {
              // Start loading previous level immediately
              ref.read(levelControllerProvider.notifier).getLevel(prevLevelId);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _pageController.jumpToPage(_currentPageIndex);
                }
              });
              return;
            } else if (loadingStatus == true) {
              // Still loading, keep blocking back scroll
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _pageController.jumpToPage(_currentPageIndex);
                }
              });
              return;
            }
            // Else: loadingStatus == false -> previous level loaded; allow back scroll
          }
        }
      }

      // Check if we can scroll back
      if (!_canScrollBack(_currentPageIndex)) {
        // Block the scroll back
        setState(() {
          _isScrollBackBlocked = true;
        });

        // Check if we're at the first level
        if (_isAtFirstLevel(_currentPageIndex)) {
          // Show alert that this is the first level
          showSnackBar(
            context,
            message: choose(
              hindi: 'ये पहला लेवल है। आप पीछे नहीं जा सकते हैं।',
              hinglish: 'Ye pehla level hai. Aap pichhe nahi ja sakte hain.',
              lang: ref.read(langControllerProvider),
            ),
            type: SnackBarType.info,
          );

          // Prevent the scroll by jumping back to current position
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _pageController.jumpToPage(_currentPageIndex);
            }
          });
          return;
        }

        // Check if we need to fetch previous levels
        final levelState = ref.read(levelControllerProvider);
        final orderedIds = levelState.orderedIds;

        if (orderedIds != null && orderedIds.isNotEmpty) {
          // Find the first loaded level ID from the buffer
          String? firstLoadedLevelId;
          for (int i = 0; i < bufferSize; i++) {
            if (_sublevelBuffer[i] != null) {
              firstLoadedLevelId = _sublevelBuffer[i]!.levelId;
              break;
            }
          }

          if (firstLoadedLevelId != null) {
            final firstLoadedIndex = orderedIds.indexOf(firstLoadedLevelId);

            // If there are previous levels available to fetch
            if (firstLoadedIndex > 0) {
              // Show loading message
              showSnackBar(
                context,
                message: choose(
                  hindi: 'पिछले लेवल लोड हो रहे हैं...',
                  hinglish: 'Pichle levels load ho rahe hain...',
                  lang: ref.read(langControllerProvider),
                ),
                type: SnackBarType.info,
              );

              // Fetch previous levels
              _fetchPreviousLevelsIfNeeded();

              // Prevent the scroll by jumping back to current position
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _pageController.jumpToPage(_currentPageIndex);
                }
              });
              return;
            }
          }
        }

        // If we can't fetch more levels, show message
        showSnackBar(
          context,
          message: choose(
            hindi: 'पिछले लेवल उपलब्ध नहीं हैं',
            hinglish: 'Pichle levels available nahi hain',
            lang: ref.read(langControllerProvider),
          ),
          type: SnackBarType.info,
        );

        // Prevent the scroll by jumping back to current position
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pageController.jumpToPage(_currentPageIndex);
          }
        });
        return;
      }
    }

    // Reset scroll back blocked state if not scrolling back
    if (_isScrollBackBlocked) {
      setState(() {
        _isScrollBackBlocked = false;
      });
    }

    // Prevent scrolling forward beyond the first null (error page) after loaded content
    if (isScrollingForward) {
      final maxForwardIndex = _getMaxForwardScrollableIndex();
      if (currentPage > maxForwardIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pageController.jumpToPage(maxForwardIndex);
          }
        });
        return;
      }
    }
  }

  /// Maps a buffer index (0..bufferSize) to the corresponding index
  /// in `widget.sublevels` list. Returns null if not resolvable.
  int? _mapBufferIndexToListIndex(int bufferIndex) {
    if (bufferIndex < 0 || bufferIndex >= bufferSize) return null;

    SubLevel? resolveNearestNonNull(int start) {
      if (_sublevelBuffer[start] != null) return _sublevelBuffer[start];
      // Search backwards then forwards for the nearest non-null
      for (int offset = 1; offset < bufferSize; offset++) {
        final left = start - offset;
        if (left >= 0 && _sublevelBuffer[left] != null) return _sublevelBuffer[left];
        final right = start + offset;
        if (right < bufferSize && _sublevelBuffer[right] != null) return _sublevelBuffer[right];
        if (left < 0 && right >= bufferSize) break;
      }
      return null;
    }

    final sublevel = resolveNearestNonNull(bufferIndex);
    if (sublevel == null) return null;

    // Find the matching sublevel in widget.sublevels by levelId + index
    final listIndex = widget.sublevels.indexWhere((s) => s.levelId == sublevel.levelId && s.index == sublevel.index);

    return listIndex == -1 ? null : listIndex;
  }

  void _goNextSublevel(int index) {
    developer.log('🔄 Starting _goNextSublevel() from index: $index');

    ref.read(sublevelControllerProvider.notifier).setHasFinishedSublevel(true);
    developer.log('✅ Marked sublevel as finished');

    // Find the next non-null sublevel in the buffer
    int nextIndex = index + 1;
    developer.log('🔍 Looking for next non-null sublevel starting from index: $nextIndex');

    while (nextIndex < bufferSize && _sublevelBuffer[nextIndex] == null) {
      developer.log('⏭️ Buffer[$nextIndex] is null, checking next position...');
      nextIndex++;
    }

    if (nextIndex < bufferSize) {
      final nextSublevel = _sublevelBuffer[nextIndex];
      developer.log('🎯 Found next sublevel at buffer[$nextIndex]: ${nextSublevel?.level}-${nextSublevel?.index}');
      _pageController.animateToPage(nextIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      developer.log('📱 Animating to page $nextIndex');
    } else {
      developer.log('⚠️ No next sublevel found in buffer (reached end)');
    }
    developer.log('✅ _goNextSublevel() completed');
  }

  /// Jumps to the first sublevel (level 1, sublevel 1) in the buffer
  void _jumpToPage() {
    developer.log('🔄 Starting _jumpToPage() - jumping to first sublevel (1-1)');

    // Find the first sublevel (level 1, sublevel 1) in the buffer
    for (int i = 0; i < bufferSize; i++) {
      final sublevel = _sublevelBuffer[i];
      if (sublevel != null && sublevel.level == 1 && sublevel.index == 1) {
        developer.log('🎯 Found first sublevel (1-1) at buffer position $i');
        _pageController.jumpToPage(i);
        developer.log('📱 Jumped to page $i');
        break;
      }
    }
    developer.log('✅ _jumpToPage() completed');
  }

  /// Gets the current sublevel from the buffer at the given index
  SubLevel? _getCurrentSublevel(int index) {
    if (index >= 0 && index < bufferSize) {
      final sublevel = _sublevelBuffer[index];
      if (sublevel != null) {
        developer.log('🔍 _getCurrentSublevel($index): Level ${sublevel.level}-${sublevel.index}');
      } else {
        developer.log('🔍 _getCurrentSublevel($index): null (empty buffer position)');
      }
      return sublevel;
    }
    developer.log('⚠️ _getCurrentSublevel($index): Index out of bounds');
    return null;
  }

  /// Logs disabled in production. Kept as a no-op for potential future debugging.
  void _logBufferState(String operation) {
    // Enable logging by uncommenting the lines below
    developer.log('=== BUFFER STATE: $operation ===');
    developer.log('Current Page Index: $_currentPageIndex');

    // Log non-null entries with their positions
    List<String> nonNullEntries = [];
    for (int i = 0; i < bufferSize; i++) {
      if (_sublevelBuffer[i] != null) {
        final sublevel = _sublevelBuffer[i]!;
        nonNullEntries.add('[$i]: Level ${sublevel.level}-${sublevel.index} (${sublevel.levelId})');
      }
    }

    if (nonNullEntries.isNotEmpty) {
      developer.log('Non-null entries:');
      for (String entry in nonNullEntries) {
        developer.log('  $entry');
      }
    } else {
      developer.log('Buffer is empty (all null)');
    }
    developer.log('========================');
  }

  void _fillBuffer() {
    developer.log('🔄 Starting _fillBuffer()');

    for (int i = 0; i < bufferSize; i++) {
      _sublevelBuffer[i] = null;
    }
    developer.log('📝 Cleared buffer (all positions set to null)');

    if (widget.sublevels.isEmpty) {
      developer.log('⚠️ No sublevels available, buffer remains empty');
      return;
    }

    // Get current progress to determine the current sublevel
    final currentProgress = ref.read(uIControllerProvider).currentProgress;
    final currentLevel = currentProgress?.level ?? 1;
    final currentSublevel = currentProgress?.subLevel ?? 1;
    developer.log('📍 Current progress: Level $currentLevel, Sublevel $currentSublevel');

    // Find the current sublevel in the list
    int currentSublevelIndex = -1;
    for (int i = 0; i < widget.sublevels.length; i++) {
      if (widget.sublevels[i].level == currentLevel && widget.sublevels[i].index == currentSublevel) {
        currentSublevelIndex = i;
        break;
      }
    }

    // If current sublevel not found, use the first one
    if (currentSublevelIndex == -1) {
      currentSublevelIndex = 0;
      developer.log('⚠️ Current sublevel not found, using first sublevel at index 0');
    }

    // Place current sublevel at middle index
    _sublevelBuffer[middleIndex] = widget.sublevels[currentSublevelIndex];
    developer.log(
      '🎯 Placed current sublevel at buffer position $middleIndex: Level ${widget.sublevels[currentSublevelIndex].level}-${widget.sublevels[currentSublevelIndex].index}',
    );

    // Sort sublevels by level and sublevel for proper ordering
    final sortedSublevels = List<SubLevel>.from(widget.sublevels);
    sortedSublevels.sort((a, b) {
      if (isLevelAfter(a.level, a.index, b.level, b.index)) {
        return 1;
      } else if (isLevelEqual(a.level, a.index, b.level, b.index)) {
        return 0;
      } else {
        return -1;
      }
    });

    // Find the position of current sublevel in sorted list
    final currentSortedIndex = sortedSublevels.indexOf(widget.sublevels[currentSublevelIndex]);
    developer.log('📊 Current sublevel position in sorted list: $currentSortedIndex');

    // Fill sublevels before current (going backwards from middle)
    int bufferIndex = middleIndex - 1;
    int filledBefore = 0;
    for (int i = currentSortedIndex - 1; i >= 0 && bufferIndex >= 0; i--) {
      _sublevelBuffer[bufferIndex] = sortedSublevels[i];
      developer.log(
        '⬅️ Filled buffer[$bufferIndex] with Level ${sortedSublevels[i].level}-${sortedSublevels[i].index}',
      );
      bufferIndex--;
      filledBefore++;
    }
    developer.log('📈 Filled $filledBefore sublevels before current position');

    // Fill sublevels after current (going forwards from middle)
    bufferIndex = middleIndex + 1;
    int filledAfter = 0;
    for (int i = currentSortedIndex + 1; i < sortedSublevels.length && bufferIndex < bufferSize; i++) {
      _sublevelBuffer[bufferIndex] = sortedSublevels[i];
      developer.log(
        '➡️ Filled buffer[$bufferIndex] with Level ${sortedSublevels[i].level}-${sortedSublevels[i].index}',
      );
      bufferIndex++;
      filledAfter++;
    }
    developer.log('📈 Filled $filledAfter sublevels after current position');

    _logBufferState('Initial Fill');
    developer.log('✅ _fillBuffer() completed');
  }

  /// Updates the buffer when new sublevels are added
  /// After initial setup, just adds sublevels according to their natural order
  void _updateBuffer() {
    developer.log('🔄 Starting _updateBuffer()');

    if (widget.sublevels.isEmpty) {
      developer.log('⚠️ No sublevels available, buffer update skipped');
      return;
    }

    developer.log('📊 Total sublevels to process: ${widget.sublevels.length}');

    // Sort all sublevels by level and sublevel for proper ordering
    final sortedSublevels = List<SubLevel>.from(widget.sublevels);
    sortedSublevels.sort((a, b) {
      if (isLevelAfter(a.level, a.index, b.level, b.index)) {
        return 1;
      } else if (isLevelEqual(a.level, a.index, b.level, b.index)) {
        return 0;
      } else {
        return -1;
      }
    });

    int referenceIndex = -1;

    final currentBuffered = _getCurrentSublevel(_currentPageIndex);
    if (currentBuffered != null) {
      developer.log(
        '🎯 Using current buffered sublevel as reference: Level ${currentBuffered.level}-${currentBuffered.index}',
      );
      for (int i = 0; i < sortedSublevels.length; i++) {
        if (isLevelEqual(
          currentBuffered.level,
          currentBuffered.index,
          sortedSublevels[i].level,
          sortedSublevels[i].index,
        )) {
          referenceIndex = i;
          developer.log('✅ Found reference sublevel at sorted index $i');
          break;
        }
      }
    }

    // 2) Try user's current progress
    if (referenceIndex == -1) {
      developer.log('🔍 Current buffered sublevel not found, trying user progress...');
      final currentProgress = ref.read(uIControllerProvider).currentProgress;
      final progressLevel = currentProgress?.level ?? 1;
      final progressSublevel = currentProgress?.subLevel ?? 1;
      developer.log('📍 User progress: Level $progressLevel, Sublevel $progressSublevel');

      for (int i = 0; i < sortedSublevels.length; i++) {
        if (isLevelEqual(progressLevel, progressSublevel, sortedSublevels[i].level, sortedSublevels[i].index)) {
          referenceIndex = i;
          developer.log('✅ Found reference sublevel using user progress at sorted index $i');
          break;
        }
      }
    }

    // 3) Fall back to 1-1
    if (referenceIndex == -1) {
      developer.log('🔍 User progress not found, falling back to Level 1-1...');
      for (int i = 0; i < sortedSublevels.length; i++) {
        if (sortedSublevels[i].level == 1 && sortedSublevels[i].index == 1) {
          referenceIndex = i;
          developer.log('✅ Found reference sublevel at Level 1-1, sorted index $i');
          break;
        }
      }
    }

    // 4) Final fallback
    if (referenceIndex == -1) {
      referenceIndex = 0;
      developer.log('⚠️ No reference found, using first sublevel as fallback');
    }

    developer.log(
      '🎯 Final reference index: $referenceIndex (Level ${sortedSublevels[referenceIndex].level}-${sortedSublevels[referenceIndex].index})',
    );

    // Clear the buffer first
    developer.log('🧹 Clearing buffer...');
    for (int i = 0; i < bufferSize; i++) {
      _sublevelBuffer[i] = null;
    }

    // Anchor the current visible page to remain stable during updates
    final anchorBufferIndex = _currentPageIndex.clamp(0, bufferSize - 1);
    developer.log('⚓ Anchoring buffer at index $anchorBufferIndex (current page: $_currentPageIndex)');

    // Place the reference sublevel at the anchor index
    _sublevelBuffer[anchorBufferIndex] = sortedSublevels[referenceIndex];
    developer.log(
      '🎯 Placed reference sublevel at buffer[$anchorBufferIndex]: Level ${sortedSublevels[referenceIndex].level}-${sortedSublevels[referenceIndex].index}',
    );

    // Fill sublevels before the reference (going backwards from anchor)
    int bufferIndex = anchorBufferIndex - 1;
    int filledBefore = 0;
    for (int i = referenceIndex - 1; i >= 0 && bufferIndex >= 0; i--) {
      _sublevelBuffer[bufferIndex] = sortedSublevels[i];
      developer.log(
        '⬅️ Filled buffer[$bufferIndex] with Level ${sortedSublevels[i].level}-${sortedSublevels[i].index}',
      );
      bufferIndex--;
      filledBefore++;
    }
    developer.log('📈 Filled $filledBefore sublevels before reference position');

    // Fill sublevels after the reference (going forwards from anchor)
    bufferIndex = anchorBufferIndex + 1;
    int filledAfter = 0;
    for (int i = referenceIndex + 1; i < sortedSublevels.length && bufferIndex < bufferSize; i++) {
      _sublevelBuffer[bufferIndex] = sortedSublevels[i];
      developer.log(
        '➡️ Filled buffer[$bufferIndex] with Level ${sortedSublevels[i].level}-${sortedSublevels[i].index}',
      );
      bufferIndex++;
      filledAfter++;
    }
    developer.log('📈 Filled $filledAfter sublevels after reference position');

    _logBufferState('Update');
    developer.log('✅ _updateBuffer() completed');
  }

  bool _isLoadingRelevantLevels(WidgetRef ref) {
    developer.log('🔍 Checking if loading relevant levels...');

    // If we have no sublevels in buffer, any loading is relevant
    bool hasSublevels = false;
    for (int i = 0; i < bufferSize; i++) {
      if (_sublevelBuffer[i] != null) {
        hasSublevels = true;
        break;
      }
    }

    if (!hasSublevels) {
      developer.log('⚠️ No sublevels in buffer, any loading is relevant: ${widget.loadingById.isNotEmpty}');
      return widget.loadingById.isNotEmpty;
    }

    final levelState = ref.read(levelControllerProvider);
    final orderedIds = levelState.orderedIds;

    // If we don't have orderedIds, fall back to checking any loading
    if (orderedIds == null) {
      developer.log(
        '⚠️ No ordered IDs available, falling back to checking any loading: ${widget.loadingById.isNotEmpty}',
      );
      return widget.loadingById.isNotEmpty;
    }

    // Find the last loaded level ID from the buffer
    String? lastLoadedLevelId;
    for (int i = bufferSize - 1; i >= 0; i--) {
      if (_sublevelBuffer[i] != null) {
        lastLoadedLevelId = _sublevelBuffer[i]!.levelId;
        developer.log('🎯 Last loaded level ID from buffer: $lastLoadedLevelId at position $i');
        break;
      }
    }

    if (lastLoadedLevelId == null) {
      developer.log(
        '⚠️ No last loaded level found in buffer, falling back to checking any loading: ${widget.loadingById.isNotEmpty}',
      );
      return widget.loadingById.isNotEmpty;
    }

    final lastLoadedIndex = orderedIds.indexOf(lastLoadedLevelId);
    developer.log('📍 Last loaded level position in ordered IDs: $lastLoadedIndex');

    // If we can't find the last loaded level in orderedIds, fall back to checking any loading
    if (lastLoadedIndex == -1) {
      developer.log(
        '⚠️ Last loaded level not found in ordered IDs, falling back to checking any loading: ${widget.loadingById.isNotEmpty}',
      );
      return widget.loadingById.isNotEmpty;
    }

    // Check if we're loading any levels after the last loaded level
    for (int i = lastLoadedIndex + 1; i < orderedIds.length; i++) {
      final levelId = orderedIds[i];
      if (widget.loadingById[levelId] == true) {
        developer.log('✅ Found relevant loading for level: $levelId');
        return true;
      }
    }

    developer.log('ℹ️ No relevant levels currently loading');
    return false;
  }

  @override
  void initState() {
    super.initState();
    developer.log('🚀 SublevelsList initState() called');
    _pageController = PageController(initialPage: middleIndex);
    _currentPageIndex = middleIndex;
    developer.log('📱 PageController initialized with middleIndex: $middleIndex');

    _fillBuffer();

    // Add listener to prevent scroll back when appropriate
    _pageController.addListener(_onPageControllerUpdate);
    developer.log('👂 PageController listener added');

    // Ensure the initially visible page is treated as current and triggers callbacks
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      developer.log('🔄 Post-frame callback executing...');
      // Set app bar visibility based on current sublevel type
      final initialSublevel = _sublevelBuffer[_currentPageIndex];
      if (initialSublevel != null) {
        developer.log('🎯 Initial sublevel type: ${initialSublevel.runtimeType}');
        initialSublevel.when(
          video: (video) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(false),
          speechExercise: (speechExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
          arrangeExercise: (arrangeExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
          fillExercise: (fillExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
        );
      }

      // Notify initial sublevel change with the correct list index
      developer.log('✅ Post-frame callback completed');
    });
    developer.log('✅ initState() completed');
  }

  @override
  void didUpdateWidget(covariant SublevelsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    developer.log('🔄 didUpdateWidget() called');
    developer.log('📊 Old sublevels count: ${oldWidget.sublevels.length}');
    developer.log('📊 New sublevels count: ${widget.sublevels.length}');

    if (oldWidget.sublevels.length != widget.sublevels.length) {
      developer.log('📈 Sublevels count changed, updating buffer...');
      _updateBuffer();

      // If we were loading previous levels and now have more sublevels,
      // we can allow scroll back
      if (_isLoadingPreviousLevels && _canScrollBack(_currentPageIndex)) {
        developer.log('✅ Previous levels loaded, enabling scroll back');
        setState(() {
          _isLoadingPreviousLevels = false;
        });

        // Show success message that scroll back is now possible
        if (mounted) {
          showSnackBar(
            context,
            message: choose(
              hindi: 'अब आप पिछले लेवल्स देख सकते हैं',
              hinglish: 'Ab aap pichle levels dekh sakte hain',
              lang: ref.read(langControllerProvider),
            ),
            type: SnackBarType.success,
          );
        }

        // Also reset the scroll back blocked state
        if (_isScrollBackBlocked) {
          developer.log('🔄 Resetting scroll back blocked state');
          setState(() {
            _isScrollBackBlocked = false;
          });
        }
      }
    }
    developer.log('✅ didUpdateWidget() completed');
  }

  @override
  void dispose() {
    developer.log('🗑️ SublevelsList dispose() called');
    _pageController.removeListener(_onPageControllerUpdate);
    developer.log('👂 PageController listener removed');
    _pageController.dispose();
    developer.log('📱 PageController disposed');
    super.dispose();
    developer.log('✅ dispose() completed');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userControllerProvider.select((value) => value.currentUser), (previous, next) {
      developer.log('👤 User controller listener triggered');
      if (next == null) {
        developer.log('⚠️ User is null, skipping profile reset logic');
        return;
      }

      developer.log('✅ User updated, checking if profile is reset...');
      //  if profile is reset, jump to first sublevel
      final progress = ref.read(uIControllerProvider).currentProgress;
      final currentIndex = _pageController.page?.round() ?? 0;
      developer.log('📍 Current progress: Level ${progress?.level}-${progress?.subLevel}');
      developer.log('📍 Current page index: $currentIndex');

      if (progress?.level == 1 && progress?.subLevel == 1) {
        developer.log('🔄 Profile reset detected (Level 1-1), updating buffer and jumping to first sublevel');
        // Ensure buffer is rebuilt around new progress so 1-1 exists in buffer
        _updateBuffer();
        final currentSublevel = _sublevelBuffer[currentIndex];
        if (currentSublevel == null || !(currentSublevel.level == 1 && currentSublevel.index == 1)) {
          developer.log('🎯 Jumping to first sublevel (1-1)');
          _jumpToPage();
        } else {
          developer.log('ℹ️ Already at first sublevel (1-1)');
        }
      } else {
        developer.log('ℹ️ No profile reset detected');
      }
    });

    ref.listen(sublevelControllerProvider.select((value) => value.hasFinishedSublevel), (previous, next) {
      developer.log('🎯 Sublevel controller listener triggered');
      developer.log('📊 Previous hasFinishedSublevel: $previous');
      developer.log('📊 Current hasFinishedSublevel: $next');

      final progress = ref.read(uIControllerProvider).currentProgress;
      developer.log('📍 Current progress: Level ${progress?.level}-${progress?.subLevel}');
      developer.log('📍 Max progress: Level ${progress?.maxLevel}-${progress?.maxSubLevel}');

      if (!isLevelEqual(
            progress?.level ?? 0,
            progress?.subLevel ?? 0,
            progress?.maxLevel ?? 0,
            progress?.maxSubLevel ?? 0,
          ) ||
          !next) {
        developer.log('ℹ️ Conditions not met for animation, skipping...');
        return;
      }

      developer.log('✅ Conditions met for animation, but animation is now handled in VideoPlayerScreen');
      // Animation is now handled in VideoPlayerScreen
    });

    // Animation control is now handled in VideoPlayerScreen

    return RefreshIndicator(
      onRefresh: () async {
        developer.log('🔄 Refresh indicator triggered');
        // Find the first non-null sublevel in the buffer
        for (int i = 0; i < bufferSize; i++) {
          final sublevel = _sublevelBuffer[i];
          if (sublevel != null) {
            if (sublevel.level == 1 && sublevel.index == 1) {
              developer.log('ℹ️ Already at first sublevel (1-1), refresh not needed');
              return;
            }
            developer.log('🎯 First sublevel found at buffer[$i]: Level ${sublevel.level}-${sublevel.index}');
            break;
          }
        }

        developer.log('⏳ Delaying refresh for 5 seconds...');
        await Future.delayed(const Duration(seconds: 5));
        developer.log('✅ Refresh delay completed');
      },
      child: Container(
        color: Colors.black,
        child: PageView.builder(
          controller: _pageController,
          allowImplicitScrolling: true,
          dragStartBehavior: DragStartBehavior.down,
          itemCount: bufferSize,
          scrollDirection: Axis.vertical,
          onPageChanged: (index) async {
            developer.log('📱 Page changed from $_currentPageIndex to $index');

            // Capture previous sublevel before updating index
            final previousSublevel = _getCurrentSublevel(_currentPageIndex);
            if (previousSublevel != null) {
              developer.log('⬅️ Previous sublevel: Level ${previousSublevel.level}-${previousSublevel.index}');
            }

            setState(() {
              _currentPageIndex = index;
            });
            developer.log('🔄 Current page index updated to: $_currentPageIndex');

            // Log current L-S after page change (removed)

            // Control app bar visibility based on sublevel type
            final sublevel = _sublevelBuffer[index];
            if (sublevel != null) {
              developer.log('🎯 New sublevel type: ${sublevel.runtimeType}');
              sublevel.when(
                video: (video) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(false),
                speechExercise: (speechExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
                arrangeExercise: (arrangeExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
                fillExercise: (fillExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
              );
            }

            // Mark the previous exercise type as seen so its description won't show next time
            if (previousSublevel != null) {
              developer.log('👁️ Marking previous exercise as seen...');
              final userEmail = ref.read(userControllerProvider.notifier).getUser()?.email;
              await previousSublevel.when(
                video: (_) async {},
                speechExercise:
                    (_) async => await ref
                        .read(uIControllerProvider.notifier)
                        .setExerciseSeen(SubLevelType.speech, userEmail: userEmail),
                arrangeExercise:
                    (_) async => await ref
                        .read(uIControllerProvider.notifier)
                        .setExerciseSeen(SubLevelType.arrange, userEmail: userEmail),
                fillExercise:
                    (_) async => await ref
                        .read(uIControllerProvider.notifier)
                        .setExerciseSeen(SubLevelType.fill, userEmail: userEmail),
              );
            }

            // Fetch the level whenever the level changes (not sublevel)
            final expectedAtIndex = _expectedSublevelAt(index);
            if (expectedAtIndex != null) {
              final prevLevelId = previousSublevel?.levelId;
              final newLevelId = expectedAtIndex.levelId;
              if (prevLevelId != newLevelId) {
                developer.log('🔄 Level changed from $prevLevelId to $newLevelId, fetching new level...');
                final levelState = ref.read(levelControllerProvider);
                final isKnown = levelState.loadingById.containsKey(newLevelId);
                if (!isKnown) {
                  developer.log('📥 Fetching level: $newLevelId');
                  await ref.read(levelControllerProvider.notifier).getLevel(newLevelId);
                } else {
                  developer.log('ℹ️ Level $newLevelId already known');
                }
              }
            }

            // Map buffer index to list index before notifying
            final listIndex = _mapBufferIndexToListIndex(index);
            if (listIndex != null) {
              developer.log('📞 Calling onSublevelChange with listIndex: $listIndex');
              await widget.onSublevelChange?.call(listIndex, _pageController);
            } else {
              developer.log('⚠️ Could not map buffer index $index to list index');
            }

            developer.log('✅ Page change handling completed');
          },
          itemBuilder: (context, index) {
            final sublevel = _sublevelBuffer[index];

            final isLoading =
                sublevel == null ? _isLoadingRelevantLevels(ref) : (widget.loadingById[sublevel.levelId] ?? true);

            if (sublevel == null && !isLoading) {
              // Check if we're loading previous levels
              if (_isLoadingPreviousLevels) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      LangText.bodyText(
                        text: choose(
                          hindi: 'पिछले लेवल लोड हो रहे हैं...',
                          hinglish: 'Pichle levels load ho rahe hain...',
                          lang: ref.read(langControllerProvider),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }

              final levelState = ref.read(levelControllerProvider);
              final orderedIds = levelState.orderedIds;
              final lastAvailableLevelId = orderedIds?.last;

              // Find the last non-null sublevel in the buffer
              String? lastLoadedLevelId;
              for (int i = bufferSize - 1; i >= 0; i--) {
                if (_sublevelBuffer[i] != null) {
                  lastLoadedLevelId = _sublevelBuffer[i]!.levelId;
                  break;
                }
              }

              final isAtLastAvailableLevel =
                  lastAvailableLevelId != null &&
                  lastLoadedLevelId != null &&
                  lastLoadedLevelId == lastAvailableLevelId;

              if (isAtLastAvailableLevel) {
                return ErrorPage(
                  onButtonClick: () async {
                    // Show loading feedback
                    showSnackBar(
                      context,
                      message: choose(
                        hindi: 'नए लेवल्स चेक कर रहे हैं...',
                        hinglish: 'Naye levels check kar rahe hain...',
                        lang: ref.read(langControllerProvider),
                      ),
                      type: SnackBarType.info,
                    );

                    try {
                      final levelController = ref.read(levelControllerProvider.notifier);
                      final currentOrderedIds = ref.read(levelControllerProvider).orderedIds?.length ?? 0;

                      await levelController.getOrderedIds();
                      await levelController.fetchLevels();

                      final newOrderedIds = ref.read(levelControllerProvider).orderedIds?.length ?? 0;

                      if (context.mounted) {
                        showSnackBar(
                          context,
                          message: choose(
                            hindi:
                                newOrderedIds > currentOrderedIds
                                    ? 'नए लेवल्स मिल गए! 🎉'
                                    : 'अभी कोई नए लेवल्स नहीं हैं',
                            hinglish:
                                newOrderedIds > currentOrderedIds
                                    ? 'Naye levels mil gaye! 🎉'
                                    : 'Abhi koi naye levels nahi hain',
                            lang: ref.read(langControllerProvider),
                          ),
                          type: SnackBarType.success,
                        );
                      }

                      final mapped = _mapBufferIndexToListIndex(index);
                      if (mapped != null) {
                        await widget.onSublevelChange?.call(mapped, _pageController);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showSnackBar(
                          context,
                          message: choose(
                            hindi: 'कुछ गलत हुआ। कृपया बाद में कोशिश करें।',
                            hinglish: 'Kuch galat hua. Kripya baad mein koshish karein.',
                            lang: ref.read(langControllerProvider),
                          ),
                          type: SnackBarType.error,
                        );
                      }
                    }
                  },
                  text: choose(
                    hindi: 'अभी इतने ही लेवल्स हैं। कुछ समय बाद नीचे दिए गए बटन पर क्लिक करके चेक करें।',
                    hinglish:
                        'Abhi itne he levels hai. Kuch time baad niche diye gye button par click karke check karein.',
                    lang: ref.read(langControllerProvider),
                  ),
                  buttonText: choose(
                    hindi: 'अगला लेवल लोड करें',
                    hinglish: 'Agla level load karein',
                    lang: ref.read(langControllerProvider),
                  ),
                );
              }

              final error = ref.watch(sublevelControllerProvider).error;

              if (error == null) {
                return const Loader();
              }

              return ErrorPage(
                onButtonClick: () {
                  final mapped = _mapBufferIndexToListIndex(index);
                  if (mapped != null) {
                    widget.onSublevelChange?.call(mapped, _pageController);
                  }
                },
                text: error,
                buttonText: choose(
                  hindi: 'पुनः प्रयास करें',
                  hinglish: 'Retry',
                  lang: ref.read(langControllerProvider),
                ),
              );
            }

            if (sublevel == null) {
              return const Loader();
            }

            return Center(
              child: sublevel.when(
                video:
                    (video) => VideoPlayerScreen(
                      video: Video(
                        id: video.id,
                        levelId: video.levelId,
                        level: sublevel.level,
                        index: sublevel.index,
                        dialogues: video.dialogues,
                      ),
                      isCurrent: _currentPageIndex == index,
                    ),
                speechExercise:
                    (speechExercise) => SpeechExerciseScreen(
                      exercise: speechExercise,
                      goToNext: () => _goNextSublevel(index),
                      isCurrent: _currentPageIndex == index,
                    ),
                arrangeExercise:
                    (arrangeExercise) => ArrangeExerciseScreen(
                      exercise: arrangeExercise,
                      goToNext: () => _goNextSublevel(index),
                      isCurrent: _currentPageIndex == index,
                    ),
                fillExercise:
                    (fillExercise) => FillExerciseScreen(
                      exercise: fillExercise,
                      goToNext: () => _goNextSublevel(index),
                      isCurrent: _currentPageIndex == index,
                    ),
              ),
            );
          },
        ),
      ),
    );
  }
}
