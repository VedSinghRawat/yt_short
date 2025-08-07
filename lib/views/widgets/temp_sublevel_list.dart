import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/views/widgets/loader.dart';
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
import 'dart:async';
import 'dart:developer' as developer;

class TempSublevelsList extends ConsumerStatefulWidget {
  final List<SubLevel> sublevels;
  final Map<String, bool> loadingById;
  final Future<void> Function(int index, PageController controller)? onSublevelChange;

  const TempSublevelsList({super.key, required this.sublevels, this.onSublevelChange, required this.loadingById});

  @override
  ConsumerState<TempSublevelsList> createState() => _TempSublevelsListState();
}

class _TempSublevelsListState extends ConsumerState<TempSublevelsList> {
  late PageController _controller;

  // Dynamic buffer management - key to preventing flicker
  static const int _bufferSize = 7; // Should be odd number (3, 5, 7, etc.)
  late int _middleIndex;
  final List<SubLevel> _bufferSublevels = [];
  int _currentGlobalIndex = 0; // Current position in the full widget.sublevels list

  // Track which buffer positions contain duplicates (padding)
  final List<bool> _isDuplicate = [];

  @override
  void initState() {
    super.initState();

    // Initialize buffer with current user progress first
    _initializeBuffer();

    // Initialize controller to start at middle (calculated in _initializeBuffer)
    _controller = PageController(initialPage: _middleIndex);

    // Set up controller listener - this is the key from StackOverflow solution
    _controller.addListener(_onControllerChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToCurrentProgress();
    });
  }

  void _initializeBuffer() {
    if (widget.sublevels.isEmpty) {
      _middleIndex = (_bufferSize / 2).floor();
      return;
    }

    // Find current progress position - THIS IS THE MIDDLE
    final progress = ref.read(uIControllerProvider).currentProgress;

    developer.log(
      '🎯 User progress: ${progress?.level}-${progress?.subLevel} (levelId: ${progress?.levelId})',
      name: 'TempSublevelsList',
    );

    _currentGlobalIndex = widget.sublevels.indexWhere(
      (sublevel) => (sublevel.index == progress?.subLevel && sublevel.level == progress?.level),
    );

    if (_currentGlobalIndex < 0) {
      _currentGlobalIndex = 0;
      developer.log('⚠️ Progress not found in sublevels, defaulting to index 0', name: 'TempSublevelsList');
    } else {
      developer.log('✅ Found progress at global index $_currentGlobalIndex', name: 'TempSublevelsList');
    }

    // Middle index is always fixed
    _middleIndex = (_bufferSize / 2).floor();

    // Build buffer with current sublevel at middle, pad when needed
    _rebuildBufferWithPadding();
    developer.log(
      'Initial buffer created with current sublevel at middle. Global index $_currentGlobalIndex, middle $_middleIndex',
      name: 'TempSublevelsList',
    );
  }

  void _logBufferState(String action) {
    final bufferInfo = _bufferSublevels.map((sublevel) => '${sublevel.level}-${sublevel.index}').join(', ');
    final currentSublevel =
        _currentGlobalIndex < widget.sublevels.length
            ? '${widget.sublevels[_currentGlobalIndex].level}-${widget.sublevels[_currentGlobalIndex].index}'
            : 'N/A';

    developer.log(
      '[$action] Buffer: [$bufferInfo] | Global Index: $_currentGlobalIndex → $currentSublevel | Middle: $_middleIndex',
      name: 'TempSublevelsList',
    );
  }

  void _rebuildBufferWithPadding() {
    _bufferSublevels.clear();
    _isDuplicate.clear();

    if (widget.sublevels.isEmpty) return;

    final currentSublevel = widget.sublevels[_currentGlobalIndex];
    final firstSublevel = widget.sublevels[0];
    final lastSublevel = widget.sublevels[widget.sublevels.length - 1];

    // Build buffer with current sublevel at middle position
    for (int i = 0; i < _bufferSize; i++) {
      if (i == _middleIndex) {
        // Middle position: current sublevel
        _bufferSublevels.add(currentSublevel);
        _isDuplicate.add(false);
      } else if (i < _middleIndex) {
        // Before middle: previous sublevels or pad with FIRST sublevel
        int previousIndex = _currentGlobalIndex - (_middleIndex - i);
        if (previousIndex >= 0) {
          _bufferSublevels.add(widget.sublevels[previousIndex]);
          _isDuplicate.add(false);
        } else {
          // Pad with FIRST sublevel if no previous levels available
          _bufferSublevels.add(firstSublevel);
          _isDuplicate.add(true); // Mark as duplicate
        }
      } else {
        // After middle: next sublevels or pad with LAST sublevel
        int nextIndex = _currentGlobalIndex + (i - _middleIndex);
        if (nextIndex < widget.sublevels.length) {
          _bufferSublevels.add(widget.sublevels[nextIndex]);
          _isDuplicate.add(false);
        } else {
          // Pad with LAST sublevel if no next levels available
          _bufferSublevels.add(lastSublevel);
          _isDuplicate.add(true); // Mark as duplicate
        }
      }
    }

    developer.log(
      '🎯 Buffer built: current sublevel (${currentSublevel.level}-${currentSublevel.index}) at middle position $_middleIndex',
      name: 'TempSublevelsList',
    );

    // Log duplicate positions
    final duplicatePositions = <int>[];
    for (int i = 0; i < _isDuplicate.length; i++) {
      if (_isDuplicate[i]) duplicatePositions.add(i);
    }
    if (duplicatePositions.isNotEmpty) {
      developer.log('🚫 Duplicate positions (scroll blocked): $duplicatePositions', name: 'TempSublevelsList');
    }

    _logBufferState('PADDED_REBUILD');
  }

  void _onControllerChange() {
    if (!_controller.hasClients) return;

    final currentPage = _controller.page!;
    final targetPage = currentPage.round();

    // Check if user is trying to scroll to a duplicate page
    if (targetPage >= 0 && targetPage < _isDuplicate.length && _isDuplicate[targetPage] && targetPage != _middleIndex) {
      // Special handling for last level duplicates (ErrorPage)
      if (_isAtLastAvailableLevel() && targetPage > _middleIndex) {
        // Allow scrolling to the first ErrorPage (first duplicate after middle)
        if (targetPage == _middleIndex + 1) {
          return; // Allow scrolling to first ErrorPage
        } else {
          // Block scrolling to additional ErrorPages
          developer.log('🚫 BLOCKED scroll to additional ErrorPage at $targetPage', name: 'TempSublevelsList');
          _controller.animateToPage(
            _middleIndex + 1,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
          return;
        }
      }

      // For other duplicates, show alert and block
      developer.log('🚫 BLOCKED scroll to duplicate page $targetPage', name: 'TempSublevelsList');

      // Show appropriate alert
      if (targetPage < _middleIndex) {
        _showBackwardBlockedAlert();
      } else {
        _showForwardBlockedAlert();
      }

      // Immediately jump back to middle to prevent any visual movement
      _controller.animateToPage(_middleIndex, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
      return;
    }

    // Determine direction and check if we need to load more content
    if (currentPage > _middleIndex) {
      // Swiping right (going forward)
      final index = currentPage.floor();
      if (index == _middleIndex + 1) {
        _moveForward();
      }
    } else if (currentPage < _middleIndex) {
      // Swiping left (going backward)
      final index = currentPage.ceil();
      if (index == _middleIndex - 1) {
        _moveBackward();
      }
    }
  }

  void _moveForward() {
    // Move global index forward
    _currentGlobalIndex++;

    // Check if we need to load more content
    if (_currentGlobalIndex >= widget.sublevels.length - 2) {
      // Near the end, trigger loading more levels
      widget.onSublevelChange?.call(_currentGlobalIndex, _controller);
    }

    setState(() {
      if (_currentGlobalIndex < widget.sublevels.length) {
        // Remove first item, add new item to end
        _bufferSublevels.removeAt(0);
        _isDuplicate.removeAt(0);

        int newIndex = _currentGlobalIndex + _middleIndex;
        if (newIndex < widget.sublevels.length) {
          _bufferSublevels.add(widget.sublevels[newIndex]);
          _isDuplicate.add(false);
        } else {
          _bufferSublevels.add(widget.sublevels[widget.sublevels.length - 1]);
          _isDuplicate.add(true); // Mark as duplicate
        }
      }
    });

    _triggerSublevelChange();

    _logBufferState('MOVE_FORWARD');

    // Jump back to middle - this prevents flicker
    _controller.jumpToPage(_middleIndex);
  }

  void _moveBackward() {
    // Move global index backward
    _currentGlobalIndex--;

    if (_currentGlobalIndex < 0) {
      _currentGlobalIndex = 0;
      return;
    }

    setState(() {
      // Remove last item, add new item to beginning
      _bufferSublevels.removeLast();
      _isDuplicate.removeLast();

      int newIndex = _currentGlobalIndex - _middleIndex;
      if (newIndex >= 0) {
        _bufferSublevels.insert(0, widget.sublevels[newIndex]);
        _isDuplicate.insert(0, false);
      } else {
        _bufferSublevels.insert(0, widget.sublevels[0]);
        _isDuplicate.insert(0, true); // Mark as duplicate
      }
    });

    _triggerSublevelChange();

    _logBufferState('MOVE_BACKWARD');

    // Jump back to middle - this prevents flicker
    _controller.jumpToPage(_middleIndex);
  }

  void _triggerSublevelChange() {
    // Notify parent about current sublevel change
    widget.onSublevelChange?.call(_currentGlobalIndex, _controller);

    // Update app bar visibility
    if (_currentGlobalIndex < widget.sublevels.length) {
      final sublevel = widget.sublevels[_currentGlobalIndex];
      sublevel.when(
        video: (video) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(false),
        speechExercise: (speechExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
        arrangeExercise: (arrangeExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
        fillExercise: (fillExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
      );
    }

    developer.log('🔄 Sublevel change triggered', name: 'TempSublevelsList');
  }

  Future<void> _jumpToCurrentProgress() async {
    final userEmail = ref.read(userControllerProvider.notifier).getUser()?.email;
    final progress = ref.read(uIControllerProvider).currentProgress;

    final targetIndex = widget.sublevels.indexWhere(
      (sublevel) => (sublevel.index == progress?.subLevel && sublevel.level == progress?.level),
    );

    if (targetIndex >= 0 && targetIndex != _currentGlobalIndex) {
      final indexDifference = (targetIndex - _currentGlobalIndex).abs();

      // Only rebuild buffer if the jump is significant (more than half buffer size)
      if (indexDifference > _bufferSize ~/ 2) {
        developer.log(
          'Major jump detected: Global Index $_currentGlobalIndex → $targetIndex (diff: $indexDifference)',
          name: 'TempSublevelsList',
        );
        _currentGlobalIndex = targetIndex;
        _rebuildBufferWithPadding();

        if (mounted) {
          setState(() {});
        }
      } else {
        developer.log(
          'Minor jump detected: Global Index $_currentGlobalIndex → $targetIndex (diff: $indexDifference) - using natural scroll',
          name: 'TempSublevelsList',
        );
        // For small jumps, just update the global index and let natural scrolling handle it
        _currentGlobalIndex = targetIndex;
      }
    }

    // Store progress
    if (_currentGlobalIndex < widget.sublevels.length) {
      final jumpSublevel = widget.sublevels[_currentGlobalIndex];
      final progressUpdate = Progress(level: jumpSublevel.level, subLevel: jumpSublevel.index);
      await ref.read(uIControllerProvider.notifier).storeProgress(progressUpdate, userEmail: userEmail);
    }
  }

  void _goNextSublevel() {
    if (_currentGlobalIndex < widget.sublevels.length - 1) {
      ref.read(sublevelControllerProvider.notifier).setHasFinishedSublevel(true);
      _controller.animateToPage(_middleIndex + 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _showBackwardBlockedAlert() {
    if (!mounted) return;

    final currentSublevel = widget.sublevels[_currentGlobalIndex];
    final isFirstLevel = currentSublevel.level == 1 && currentSublevel.index == 1;

    showSnackBar(
      context,
      message: choose(
        hindi:
            isFirstLevel
                ? 'यह पहला लेवल है। इससे पीछे कोई लेवल नहीं है।'
                : 'पुराने लेवल्स लोड हो रहे हैं। कृपया थोड़ा इंतज़ार करें।',
        hinglish:
            isFirstLevel
                ? 'Ye pehla level hai. Isse peeche koi level nahi hai.'
                : 'Purane levels load ho rahe hain. Kripya thoda intezaar karein.',
        lang: ref.read(langControllerProvider),
      ),
      type: SnackBarType.info,
    );

    developer.log(
      '🚫 Backward scroll blocked: ${isFirstLevel ? "First level" : "Loading older levels"}',
      name: 'TempSublevelsList',
    );
  }

  void _showForwardBlockedAlert() {
    if (!mounted) return;

    // Show simple alert for forward scroll blocking
    showSnackBar(
      context,
      message: choose(
        hindi: 'यही अंतिम लेवल है। नए लेवल्स की जांच करने के लिए अगले पेज पर जाएं।',
        hinglish: 'Yehi antim level hai. Naye levels ki jaanch karne ke liye agle page par jayen.',
        lang: ref.read(langControllerProvider),
      ),
      type: SnackBarType.info,
    );

    developer.log('🚫 Forward scroll blocked: Last level reached', name: 'TempSublevelsList');
  }

  bool _isAtLastAvailableLevel() {
    final levelState = ref.read(levelControllerProvider);
    final orderedIds = levelState.orderedIds;
    final lastAvailableLevelId = orderedIds?.last;
    final lastLoadedLevelId = widget.sublevels.isNotEmpty ? widget.sublevels.last.levelId : null;

    return lastAvailableLevelId != null && lastLoadedLevelId != null && lastLoadedLevelId == lastAvailableLevelId;
  }

  Widget _buildSublevelContent(SubLevel sublevel, int bufferIndex) {
    return sublevel.when(
      video:
          (video) => VideoPlayerScreen(
            key: ValueKey('video_${video.id}_${sublevel.levelId}_${sublevel.index}'),
            video: video,
            isCurrent: bufferIndex == _middleIndex,
          ),
      speechExercise:
          (speechExercise) => SpeechExerciseScreen(
            exercise: speechExercise,
            goToNext: () => _goNextSublevel(),
            isCurrent: bufferIndex == _middleIndex,
          ),
      arrangeExercise:
          (arrangeExercise) => ArrangeExerciseScreen(
            exercise: arrangeExercise,
            goToNext: () => _goNextSublevel(),
            isCurrent: bufferIndex == _middleIndex,
          ),
      fillExercise:
          (fillExercise) => FillExerciseScreen(
            exercise: fillExercise,
            goToNext: () => _goNextSublevel(),
            isCurrent: bufferIndex == _middleIndex,
          ),
    );
  }

  @override
  void didUpdateWidget(covariant TempSublevelsList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle when new sublevels are loaded
    if (oldWidget.sublevels.length != widget.sublevels.length) {
      final oldLength = oldWidget.sublevels.length;
      final newLength = widget.sublevels.length;
      final itemsAdded = newLength - oldLength;

      developer.log('Sublevels count changed: $oldLength → $newLength (added: $itemsAdded)', name: 'TempSublevelsList');

      if (itemsAdded > 0) {
        // Items were added (likely prepending old levels)
        _handleNewSublevelsAdded(itemsAdded, oldWidget.sublevels);
      } else {
        // Items were removed or changed, rebuild buffer
        _rebuildBufferWithPadding();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  void _handleNewSublevelsAdded(int itemsAdded, List<SubLevel> oldSublevels) {
    // Simple prepending detection: check if old items appear after the beginning
    bool itemsPrepended = false;
    int firstOldItemNewIndex = -1;

    if (oldSublevels.isNotEmpty) {
      // Find where the first old item appears in the new list
      firstOldItemNewIndex = widget.sublevels.indexWhere(
        (sublevel) => sublevel.levelId == oldSublevels[0].levelId && sublevel.index == oldSublevels[0].index,
      );

      if (firstOldItemNewIndex > 0) {
        // Items were prepended
        itemsPrepended = true;
        developer.log(
          '✅ Items were prepended at the beginning (old items now start at index $firstOldItemNewIndex)',
          name: 'TempSublevelsList',
        );
      } else {
        developer.log('✅ Items were appended at the end (new items added to end of list)', name: 'TempSublevelsList');
      }
    }

    // Store the current sublevel info before any changes
    final currentSublevel =
        _currentGlobalIndex < widget.sublevels.length ? widget.sublevels[_currentGlobalIndex] : null;

    if (currentSublevel != null) {
      developer.log(
        '🎯 Current sublevel before adjustment: ${currentSublevel.level}-${currentSublevel.index} (global index: $_currentGlobalIndex)',
        name: 'TempSublevelsList',
      );
    }

    // Always update global index based on current progress, regardless of prepended/appended
    final progress = ref.read(uIControllerProvider).currentProgress;
    final newGlobalIndex = widget.sublevels.indexWhere(
      (sublevel) => (sublevel.index == progress?.subLevel && sublevel.level == progress?.level),
    );

    if (newGlobalIndex >= 0 && newGlobalIndex != _currentGlobalIndex) {
      developer.log(
        '📍 Updated global index based on current progress: $_currentGlobalIndex → $newGlobalIndex (${progress?.level}-${progress?.subLevel})',
        name: 'TempSublevelsList',
      );
      _currentGlobalIndex = newGlobalIndex;
    } else if (newGlobalIndex >= 0) {
      developer.log(
        '📍 Global index unchanged: $_currentGlobalIndex (${progress?.level}-${progress?.subLevel})',
        name: 'TempSublevelsList',
      );
    }

    if (itemsPrepended) {
      // Items prepended - check if we can replace left-side padding with older levels
      final hasLeftSidePadding =
          _isDuplicate.any((isDup) => isDup) && _isDuplicate.sublist(0, _middleIndex).any((isDup) => isDup);

      if (hasLeftSidePadding) {
        // Check if we have older levels that can replace the padding
        final firstBufferSublevel = _bufferSublevels[0];
        final firstGlobalSublevel = widget.sublevels[0];

        // If the first global sublevel is older than the first buffer sublevel, update buffer
        if (firstGlobalSublevel.level < firstBufferSublevel.level ||
            (firstGlobalSublevel.level == firstBufferSublevel.level &&
                firstGlobalSublevel.index < firstBufferSublevel.index)) {
          developer.log('🔄 Older levels prepended - updating buffer to replace padding', name: 'TempSublevelsList');
          _rebuildBufferWithPadding();
          if (mounted) {
            setState(() {});
          }
        } else {
          developer.log(
            'ℹ️ Items prepended but no older levels to replace padding - buffer unchanged',
            name: 'TempSublevelsList',
          );
        }
      } else {
        // No left-side padding to replace
        developer.log('ℹ️ Items prepended - buffer unchanged', name: 'TempSublevelsList');
      }
    } else {
      // For appended items, the global index should stay the same since items are added at the end
      // The current sublevel remains at the same position in the list
      developer.log(
        '📍 Global index unchanged for appended items: $_currentGlobalIndex (items added at end)',
        name: 'TempSublevelsList',
      );

      // Check if newer levels were appended that can replace right-side padding
      final hasRightSidePadding =
          _isDuplicate.any((isDup) => isDup) && _isDuplicate.sublist(_middleIndex + 1).any((isDup) => isDup);

      if (hasRightSidePadding) {
        // Check if we have newer levels that can replace the padding
        final lastBufferIndex = _bufferSublevels.length - 1;
        final lastBufferSublevel = _bufferSublevels[lastBufferIndex];
        final lastGlobalSublevel = widget.sublevels[widget.sublevels.length - 1];

        // If the last global sublevel is newer than the last buffer sublevel, update buffer
        if (lastGlobalSublevel.level > lastBufferSublevel.level ||
            (lastGlobalSublevel.level == lastBufferSublevel.level &&
                lastGlobalSublevel.index > lastBufferSublevel.index)) {
          developer.log('🔄 Newer levels appended - updating buffer to replace padding', name: 'TempSublevelsList');
          _rebuildBufferWithPadding();
          if (mounted) {
            setState(() {});
          }
        } else {
          developer.log(
            'ℹ️ Items added but no newer levels to replace padding - buffer unchanged',
            name: 'TempSublevelsList',
          );
        }
      } else {
        // No right-side padding to replace
        developer.log('ℹ️ Items added in middle or end - buffer unchanged', name: 'TempSublevelsList');
      }
    }

    // Verify the adjustment worked correctly
    if (_currentGlobalIndex < widget.sublevels.length) {
      final newCurrentSublevel = widget.sublevels[_currentGlobalIndex];
      developer.log(
        '✅ Global index adjusted: now $_currentGlobalIndex → ${newCurrentSublevel.level}-${newCurrentSublevel.index}',
        name: 'TempSublevelsList',
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bufferSublevels.isEmpty) {
      return const Loader();
    }

    // Listen for user changes
    ref.listen(userControllerProvider.select((value) => value.currentUser), (previous, next) {
      if (next == null) return;
      final progress = ref.read(uIControllerProvider).currentProgress;

      if (progress?.level == 1 && progress?.subLevel == 1) {
        _jumpToCurrentProgress();
      }
    });

    // Animation is now handled in video player screen

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentGlobalIndex == 0) return;
        await Future.delayed(const Duration(seconds: 5));
      },
      child: Container(
        color: Colors.black,
        child: PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemCount: _bufferSublevels.length,
          itemBuilder: (context, index) {
            final sublevel = _bufferSublevels[index];

            // Check if this is a duplicate at the last level - render ErrorPage instead
            if (_isAtLastAvailableLevel() && _isDuplicate[index] && index > _middleIndex) {
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ErrorPage(
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

                        await widget.onSublevelChange?.call(_currentGlobalIndex, _controller);
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
                  ),
                ),
              );
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height,
              key: ValueKey('sublevel_${sublevel.levelId}_${sublevel.index}'),
              child: Center(child: _buildSublevelContent(sublevel, index)),
            );
          },
        ),
      ),
    );
  }
}
