import 'dart:math';
import 'package:flutter/material.dart';

class ActiveMic extends StatefulWidget {
  const ActiveMic({super.key});

  @override
  State<ActiveMic> createState() => _ActiveMicState();
}

class _ActiveMicState extends State<ActiveMic> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Animation speed
  static const _animationDuration = Duration(seconds: 3);
  // Canvas size
  static const double _canvasSize = 150;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..repeat(); // repeat indefinitely
    _animation = Tween(begin: 0.0, end: 2 * pi).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _canvasSize,
      height: _canvasSize,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return const Icon(
            Icons.mic,
            size: 32,
            color: Colors.black,
          );
        },
      ),
    );
  }
}
