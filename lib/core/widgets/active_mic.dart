import 'package:flutter/material.dart';

class ActiveMic extends StatefulWidget {
  const ActiveMic({super.key});

  @override
  State<ActiveMic> createState() => _ActiveMicState();
}

class _ActiveMicState extends State<ActiveMic> with TickerProviderStateMixin {
  static const double _canvasSize = 150;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _animation.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Icon(
                Icons.mic,
                size: 32,
                color: Colors.red,
              ),
            ],
          );
        },
      ),
    );
  }
}
