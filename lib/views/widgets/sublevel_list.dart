import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/controllers/level/level_controller.dart';
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
  // Tracks where the current sublevel is anchored in the buffer; reserved for future use
  int _currentBufferIndex = middleIndex; // ignore: unused_field

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
    ref.read(sublevelControllerProvider.notifier).setHasFinishedSublevel(true);

    // Find the next non-null sublevel in the buffer
    int nextIndex = index + 1;
    while (nextIndex < bufferSize && _sublevelBuffer[nextIndex] == null) {
      nextIndex++;
    }

    if (nextIndex < bufferSize) {
      _pageController.animateToPage(nextIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  /// Jumps to the first sublevel (level 1, sublevel 1) in the buffer
  void _jumpToPage() {
    // Find the first sublevel (level 1, sublevel 1) in the buffer
    for (int i = 0; i < bufferSize; i++) {
      final sublevel = _sublevelBuffer[i];
      if (sublevel != null && sublevel.level == 1 && sublevel.index == 1) {
        _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        break;
      }
    }
  }

  /// Gets the current sublevel from the buffer at the given index
  SubLevel? _getCurrentSublevel(int index) {
    if (index >= 0 && index < bufferSize) {
      return _sublevelBuffer[index];
    }
    return null;
  }

  /// Logs the buffer state showing only relevant information
  /// Shows 3 padding of null on both sides and levels in order
  void _logBufferState(String operation) {
    // Find the range of non-null elements
    int firstNonNullIndex = -1;
    int lastNonNullIndex = -1;

    for (int i = 0; i < bufferSize; i++) {
      if (_sublevelBuffer[i] != null) {
        if (firstNonNullIndex == -1) firstNonNullIndex = i;
        lastNonNullIndex = i;
      }
    }

    if (firstNonNullIndex == -1) {
      return;
    }

    // Calculate padding range (3 on each side)
    int startIndex = (firstNonNullIndex - 3).clamp(0, bufferSize - 1);
    int endIndex = (lastNonNullIndex + 3).clamp(0, bufferSize - 1);

    for (int i = startIndex; i <= endIndex; i++) {
      final sublevel = _sublevelBuffer[i];
      if (sublevel != null) {}
    }
  }

  /// Fills the buffer with sublevels based on their level-sublevel ordering
  /// The current sublevel is placed at the middle index (500)
  /// Other sublevels are positioned before or after based on their ordering
  void _fillBuffer() {
    // Clear the buffer first
    for (int i = 0; i < bufferSize; i++) {
      _sublevelBuffer[i] = null;
    }

    if (widget.sublevels.isEmpty) {
      return;
    }

    // Get current progress to determine the current sublevel
    final currentProgress = ref.read(uIControllerProvider).currentProgress;
    final currentLevel = currentProgress?.level ?? 1;
    final currentSublevel = currentProgress?.subLevel ?? 1;

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
    }

    // Place current sublevel at middle index
    _sublevelBuffer[middleIndex] = widget.sublevels[currentSublevelIndex];
    _currentBufferIndex = middleIndex;

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

    // Fill sublevels before current (going backwards from middle)
    int bufferIndex = middleIndex - 1;
    for (int i = currentSortedIndex - 1; i >= 0 && bufferIndex >= 0; i--) {
      _sublevelBuffer[bufferIndex] = sortedSublevels[i];
      bufferIndex--;
    }

    // Fill sublevels after current (going forwards from middle)
    bufferIndex = middleIndex + 1;
    for (int i = currentSortedIndex + 1; i < sortedSublevels.length && bufferIndex < bufferSize; i++) {
      _sublevelBuffer[bufferIndex] = sortedSublevels[i];
      bufferIndex++;
    }

    _logBufferState('Initial Fill');
  }

  /// Updates the buffer when new sublevels are added
  /// After initial setup, just adds sublevels according to their natural order
  void _updateBuffer() {
    if (widget.sublevels.isEmpty) {
      return;
    }

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
      for (int i = 0; i < sortedSublevels.length; i++) {
        if (isLevelEqual(
          currentBuffered.level,
          currentBuffered.index,
          sortedSublevels[i].level,
          sortedSublevels[i].index,
        )) {
          referenceIndex = i;
          break;
        }
      }
    }

    // 2) Try user's current progress
    if (referenceIndex == -1) {
      final currentProgress = ref.read(uIControllerProvider).currentProgress;
      final progressLevel = currentProgress?.level ?? 1;
      final progressSublevel = currentProgress?.subLevel ?? 1;
      for (int i = 0; i < sortedSublevels.length; i++) {
        if (isLevelEqual(progressLevel, progressSublevel, sortedSublevels[i].level, sortedSublevels[i].index)) {
          referenceIndex = i;
          break;
        }
      }
    }

    // 3) Fall back to 1-1
    if (referenceIndex == -1) {
      for (int i = 0; i < sortedSublevels.length; i++) {
        if (sortedSublevels[i].level == 1 && sortedSublevels[i].index == 1) {
          referenceIndex = i;
          break;
        }
      }
    }

    // 4) Final fallback
    if (referenceIndex == -1) {
      referenceIndex = 0;
    }

    // Clear the buffer first
    for (int i = 0; i < bufferSize; i++) {
      _sublevelBuffer[i] = null;
    }

    // Place the reference sublevel at middle index
    _sublevelBuffer[middleIndex] = sortedSublevels[referenceIndex];
    _currentBufferIndex = middleIndex;

    // Fill sublevels before the reference (going backwards from middle)
    int bufferIndex = middleIndex - 1;
    for (int i = referenceIndex - 1; i >= 0 && bufferIndex >= 0; i--) {
      _sublevelBuffer[bufferIndex] = sortedSublevels[i];
      bufferIndex--;
    }

    // Fill sublevels after the reference (going forwards from middle)
    bufferIndex = middleIndex + 1;
    for (int i = referenceIndex + 1; i < sortedSublevels.length && bufferIndex < bufferSize; i++) {
      _sublevelBuffer[bufferIndex] = sortedSublevels[i];
      bufferIndex++;
    }

    _logBufferState('Update');
  }

  bool _isLoadingRelevantLevels(WidgetRef ref) {
    // If we have no sublevels in buffer, any loading is relevant
    bool hasSublevels = false;
    for (int i = 0; i < bufferSize; i++) {
      if (_sublevelBuffer[i] != null) {
        hasSublevels = true;
        break;
      }
    }
    if (!hasSublevels) return widget.loadingById.isNotEmpty;

    final levelState = ref.read(levelControllerProvider);
    final orderedIds = levelState.orderedIds;

    // If we don't have orderedIds, fall back to checking any loading
    if (orderedIds == null) return widget.loadingById.isNotEmpty;

    // Find the last loaded level ID from the buffer
    String? lastLoadedLevelId;
    for (int i = bufferSize - 1; i >= 0; i--) {
      if (_sublevelBuffer[i] != null) {
        lastLoadedLevelId = _sublevelBuffer[i]!.levelId;
        break;
      }
    }

    if (lastLoadedLevelId == null) return widget.loadingById.isNotEmpty;

    final lastLoadedIndex = orderedIds.indexOf(lastLoadedLevelId);

    // If we can't find the last loaded level in orderedIds, fall back to checking any loading
    if (lastLoadedIndex == -1) return widget.loadingById.isNotEmpty;

    // Check if we're loading any levels after the last loaded level
    for (int i = lastLoadedIndex + 1; i < orderedIds.length; i++) {
      final levelId = orderedIds[i];
      if (widget.loadingById[levelId] == true) {
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: middleIndex);
    _currentPageIndex = middleIndex;
    _fillBuffer();

    // Ensure the initially visible page is treated as current and triggers callbacks
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Set app bar visibility based on current sublevel type
      final initialSublevel = _sublevelBuffer[_currentPageIndex];
      if (initialSublevel != null) {
        initialSublevel.when(
          video: (video) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(false),
          speechExercise: (speechExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
          arrangeExercise: (arrangeExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
          fillExercise: (fillExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
        );
      }

      // Notify initial sublevel change with the correct list index
      final listIndex = _mapBufferIndexToListIndex(_currentPageIndex);
      if (listIndex != null) {
        await widget.onSublevelChange?.call(listIndex, _pageController);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SublevelsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sublevels.length != widget.sublevels.length) {
      _updateBuffer();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userControllerProvider.select((value) => value.currentUser), (previous, next) {
      if (next == null) return;
      //  if profile is reset, jump to first sublevel
      final progress = ref.read(uIControllerProvider).currentProgress;
      final currentIndex = _pageController.page?.round() ?? 0;

      if (progress?.level == 1 && progress?.subLevel == 1) {
        final currentSublevel = _sublevelBuffer[currentIndex];
        if (currentSublevel == null || !(currentSublevel.level == 1 && currentSublevel.index == 1)) {
          _jumpToPage();
        }
      }
    });

    ref.listen(sublevelControllerProvider.select((value) => value.hasFinishedSublevel), (previous, next) {
      final progress = ref.read(uIControllerProvider).currentProgress;

      if (!isLevelEqual(
            progress?.level ?? 0,
            progress?.subLevel ?? 0,
            progress?.maxLevel ?? 0,
            progress?.maxSubLevel ?? 0,
          ) ||
          !next) {
        return;
      }

      // Animation is now handled in VideoPlayerScreen
    });

    // Animation control is now handled in VideoPlayerScreen

    return RefreshIndicator(
      onRefresh: () async {
        // Find the first non-null sublevel in the buffer
        for (int i = 0; i < bufferSize; i++) {
          final sublevel = _sublevelBuffer[i];
          if (sublevel != null) {
            if (sublevel.level == 1 && sublevel.index == 1) return;
            break;
          }
        }

        await Future.delayed(const Duration(seconds: 5));
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
            setState(() {
              _currentPageIndex = index;
            });

            // Control app bar visibility based on sublevel type
            final sublevel = _sublevelBuffer[index];
            if (sublevel != null) {
              sublevel.when(
                video: (video) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(false),
                speechExercise: (speechExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
                arrangeExercise: (arrangeExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
                fillExercise: (fillExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
              );
            }

            // Map buffer index to list index before notifying
            final listIndex = _mapBufferIndexToListIndex(index);
            if (listIndex != null) {
              await widget.onSublevelChange?.call(listIndex, _pageController);
            }
          },
          itemBuilder: (context, index) {
            final sublevel = _sublevelBuffer[index];

            final isLoading =
                sublevel == null ? _isLoadingRelevantLevels(ref) : (widget.loadingById[sublevel.levelId] ?? true);

            if (sublevel == null && !isLoading) {
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
                onButtonClick: () => widget.onSublevelChange?.call(index, _pageController),
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
