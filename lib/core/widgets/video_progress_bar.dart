// Non-interactive timeline bar to show video progress
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoProgressBar extends StatefulWidget {
  final YoutubePlayerController controller;
  const VideoProgressBar({
    super.key,
    required this.controller,
  });

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  int _currentPosition = 0;
  double _videoDuration = 0;
  StreamSubscription? _videoStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await _startVideoStateTracking();
    });
    // Controller will be initialized in didChangeDependencies
  }

  Future<void> _startVideoStateTracking() async {
    // Initialize video duration (once)
    if (_videoDuration != 0 || !mounted) return;

    // Subscribe to video state stream for continuous updates
    _videoStateSubscription = widget.controller.videoStateStream.listen((state) async {
      if (!mounted || _currentPosition == state.position.inSeconds) return;

      if (_videoDuration == 0) {
        final duration = await widget.controller.duration;

        setState(() {
          _videoDuration = duration;
        });
      }

      setState(() {
        // Update current position from stream data
        _currentPosition = state.position.inSeconds;
      });
    }, onError: (error) {
      developer.log('Video state stream error: $error');
    });
  }

  @override
  void dispose() {
    _videoStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final progress = (_videoDuration > 0 ? _currentPosition / _videoDuration : 0.0).clamp(0.0, 1.0);

    // YouTube red color
    const youtubeRed = Color(0xFFFF0000);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // Background bar
          Container(
            height: 3,
            width: double.infinity,
            color: Colors.grey[400], // Lighter gray for background
          ),

          // Progress bar
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              height: 3,
              color: youtubeRed, // Progress color
            ),
          ),

          // Circle indicator
          Positioned(
            left: (progress * MediaQuery.of(context).size.width) - 5,
            top: -4.5,
            child: const Icon(
              Icons.circle,
              size: 12,
              color: youtubeRed,
            ),
          ),
        ],
      ),
    );
  }
}
