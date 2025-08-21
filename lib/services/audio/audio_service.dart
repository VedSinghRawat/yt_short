import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final Map<String, VideoPlayerController> _audioControllers = {};
  String? _currentPlayingPath;
  VoidCallback? _onAudioFinished;

  /// Play audio file using the file path as identifier
  Future<void> playAudio({required String audioPath, VoidCallback? onFinished}) async {
    try {
      // If same audio is playing, stop it
      if (_currentPlayingPath == audioPath && _audioControllers[audioPath]?.value.isPlaying == true) {
        await _audioControllers[audioPath]!.pause();
        _currentPlayingPath = null;
        _onAudioFinished = null;
        return;
      }

      // Stop any currently playing audio
      await _stopCurrentAudio();

      // Check if file exists
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        return;
      }

      // Get or create controller for this audio path
      VideoPlayerController controller;
      if (_audioControllers.containsKey(audioPath)) {
        controller = _audioControllers[audioPath]!;
        // Reset position to start
        await controller.seekTo(Duration.zero);
      } else {
        // Create new controller
        controller = VideoPlayerController.file(audioFile);
        _audioControllers[audioPath] = controller;

        // Add listener to track playback state
        controller.addListener(() {
          final value = controller.value;
          if (value.isInitialized) {
            // Check if audio finished
            if (value.position >= value.duration && value.duration > Duration.zero) {
              if (_currentPlayingPath == audioPath) {
                _currentPlayingPath = null;
                if (_onAudioFinished != null) {
                  _onAudioFinished!();
                  _onAudioFinished = null;
                }
              }
            }
          }
        });

        // Initialize the controller
        await controller.initialize();
      }

      // Set current audio path and callback
      _currentPlayingPath = audioPath;
      _onAudioFinished = onFinished;

      // Play the audio
      await controller.play();
    } catch (e, stack) {
      developer.log('Error in playAudio: $e', error: e, stackTrace: stack);
      _currentPlayingPath = null;
      _onAudioFinished = null;
    }
  }

  /// Stop any currently playing audio
  Future<void> _stopCurrentAudio() async {
    if (_currentPlayingPath != null && _audioControllers[_currentPlayingPath]?.value.isPlaying == true) {
      await _audioControllers[_currentPlayingPath]!.pause();
      _currentPlayingPath = null;
      _onAudioFinished = null;
    }
  }

  /// Stop current audio playback
  Future<void> stopAudio() async {
    await _stopCurrentAudio();
  }

  /// Check if audio is currently playing
  bool get isPlaying =>
      _currentPlayingPath != null && (_audioControllers[_currentPlayingPath]?.value.isPlaying ?? false);

  /// Get current playing audio path
  String? get currentPlayingPath => _currentPlayingPath;

  /// Dispose all audio controllers (call this when the app is shutting down)
  Future<void> dispose() async {
    for (final controller in _audioControllers.values) {
      await controller.dispose();
    }
    _audioControllers.clear();
    _currentPlayingPath = null;
    _onAudioFinished = null;
  }

  /// Remove a specific audio controller from cache
  Future<void> removeAudioController(String audioPath) async {
    if (_audioControllers.containsKey(audioPath)) {
      if (_currentPlayingPath == audioPath) {
        await stopAudio();
      }
      await _audioControllers[audioPath]!.dispose();
      _audioControllers.remove(audioPath);
    }
  }

  /// Get the number of cached audio controllers
  int get cachedControllersCount => _audioControllers.length;
}
