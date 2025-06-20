import 'package:flutter/material.dart';

class ScrollIndicator extends StatelessWidget {
  const ScrollIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: .3), blurRadius: 25, spreadRadius: 8)],
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
    );
  }
}
