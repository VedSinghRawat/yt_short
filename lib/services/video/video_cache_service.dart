import 'dart:developer' as developer;
import 'package:video_player/video_player.dart';
import 'package:myapp/models/video/video.dart';

class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  // Cache to store video controllers only
  final Map<String, VideoPlayerController> _controllers = {};

  String _getCacheKey(Video video) {
    // Include level and index to make cache key unique per sublevel
    return video.id;
  }

  // Store a controller in cache
  void cacheController(Video video, VideoPlayerController controller) {
    final key = _getCacheKey(video);
    _controllers[key] = controller;
    developer.log('📹 Cached controller for video: $key', name: 'VideoCacheService');
  }

  // Get cached controller
  VideoPlayerController? getCachedController(Video video) {
    final key = _getCacheKey(video);
    final controller = _controllers[key];
    if (controller != null) {
      developer.log('📹 Retrieved cached controller for video: $key', name: 'VideoCacheService');
    }
    return controller;
  }

  // Remove controller from cache
  void removeController(Video video) {
    final key = _getCacheKey(video);
    final controller = _controllers.remove(key);
    if (controller != null) {
      developer.log('📹 Removed controller from cache: $key', name: 'VideoCacheService');
    }
  }

  // Remove and dispose controller from cache
  void removeAndDisposeController(Video video) {
    final key = _getCacheKey(video);
    final controller = _controllers.remove(key);
    if (controller != null) {
      controller.dispose();
      developer.log('📹 Removed and disposed controller from cache: $key', name: 'VideoCacheService');
    }
  }

  // Clear all cached controllers
  void clearCache() {
    // Dispose all controllers before clearing
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    developer.log('📹 Cleared and disposed all cached controllers', name: 'VideoCacheService');
  }

  // Get cache size
  int get cacheSize => _controllers.length;

  // Check if video is cached
  bool isCached(Video video) {
    final key = _getCacheKey(video);
    return _controllers.containsKey(key);
  }

  // Get all cached keys
  List<String> get cachedKeys => _controllers.keys.toList();

  // Clear cache for a specific video
  void clearVideoCache(Video video) {
    final key = _getCacheKey(video);
    final controller = _controllers.remove(key);
    if (controller != null) {
      controller.dispose();
      developer.log('📹 Cleared and disposed cache for video: $key', name: 'VideoCacheService');
    }
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCached': _controllers.length,
      'cachedKeys': _controllers.keys.toList(),
      'memoryUsage': '${_controllers.length} controllers cached',
    };
  }
}
