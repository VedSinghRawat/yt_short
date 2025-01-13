import 'dart:math';
import 'package:flutter/material.dart';

class ActiveMic extends StatefulWidget {
  const ActiveMic({super.key});

  @override
  State<ActiveMic> createState() => _ActiveMicState();
}

class _ActiveMicState extends State<ActiveMic> with SingleTickerProviderStateMixin {
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
          return Stack(
            alignment: Alignment.center,
            children: [
              // Draw the filled sine waves behind the mic
              CustomPaint(
                size: const Size(_canvasSize, _canvasSize),
                painter: _SineWavePainter(
                  phase: _animation.value,
                ),
              ),
              // Mic icon on top
              const Icon(
                Icons.mic,
                size: 32,
                color: Colors.black,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SineWavePainter extends CustomPainter {
  final double phase;

  // Wave circle settings
  final double baseRadius = 40; // distance from center (beyond the icon)
  final double amplitude = 6; // “ripple” height in the circle
  final double frequency = 4; // how many ripples in one full circle

  // Bobbing settings (vertical shift of the entire wave circle)
  final double centerBobAmplitude = 5; // how many pixels to move up/down

  _SineWavePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw three filled waves, each with a phase offset for color separation
    _drawWave(canvas, center, color: const Color.fromARGB(255, 212, 108, 100).withOpacity(0.6), offset: 0.0);
    _drawWave(canvas, center, color: const Color.fromARGB(255, 133, 211, 136).withOpacity(0.6), offset: 2 * pi / 3);
    _drawWave(canvas, center, color: const Color.fromARGB(255, 89, 157, 212).withOpacity(0.6), offset: 4 * pi / 3);
  }

  void _drawWave(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double offset,
  }) {
    // Use fill style instead of stroke
    final paint = Paint()
      ..color = color // use withOpacity(...) if you want partial transparency
      ..style = PaintingStyle.fill;

    final path = Path();

    // Number of segments to sample around the circle (higher -> smoother)
    const int steps = 180;
    const stepAngle = 2 * pi / steps;

    // Vertical bob for the entire wave circle
    final waveBob = centerBobAmplitude * sin(phase + offset);

    for (int i = 0; i <= steps; i++) {
      final angle = i * stepAngle;

      // Radius of the wave at this angle
      final waveRadius = baseRadius + amplitude * sin(frequency * angle + phase + offset);

      // Coordinates
      final x = center.dx + waveRadius * cos(angle);
      final y = center.dy + waveRadius * sin(angle) + waveBob;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Close the shape so it becomes a complete fill
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SineWavePainter oldDelegate) {
    // Repaint whenever the phase changes (so the wave moves)
    return oldDelegate.phase != phase;
  }
}
