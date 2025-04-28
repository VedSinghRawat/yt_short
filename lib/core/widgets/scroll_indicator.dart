import 'package:flutter/material.dart';

class ScrollIndicator extends StatefulWidget {
  const ScrollIndicator({super.key});

  @override
  State<ScrollIndicator> createState() => _ScrollIndicatorState();
}

class _ScrollIndicatorState extends State<ScrollIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)
          ..forward()
          ..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 30.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.status == AnimationStatus.completed) {
          return const SizedBox.shrink();
        }
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, -_bounceAnimation.value),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 15, spreadRadius: 5)],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: .3 * _glowAnimation.value),
                          blurRadius: 25 * _glowAnimation.value,
                          spreadRadius: 8 * _glowAnimation.value,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_double_arrow_up_rounded,
                    color: Colors.white.withValues(alpha: .9),
                    size: 40,
                    shadows: [BoxShadow(color: Colors.white.withValues(alpha: .4), blurRadius: 20, spreadRadius: 2)],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
