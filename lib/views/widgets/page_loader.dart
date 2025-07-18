import 'package:flutter/material.dart';

class PageLoader extends StatefulWidget {
  const PageLoader({super.key});

  @override
  State<PageLoader> createState() => _PageLoaderState();
}

class _PageLoaderState extends State<PageLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/img/logo.png', width: 150),
            const SizedBox(height: 40),
            CustomPaint(size: const Size(200, 8), painter: _LoadingBarPainter(animation: _controller)),
          ],
        ),
      ),
    );
  }
}

class _LoadingBarPainter extends CustomPainter {
  final Animation<double> animation;

  _LoadingBarPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint =
        Paint()
          ..color = Colors.grey[800]!
          ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(4));

    canvas.drawRRect(rrect, backgroundPaint);
    canvas.clipRRect(rrect);

    final paint =
        Paint()
          ..color = const Color.fromARGB(255, 223, 150, 39)
          ..style = PaintingStyle.fill;

    final barWidth = size.width * 0.4;
    final totalWidth = size.width;
    final x = animation.value * totalWidth;

    // Draw the primary bar
    canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, size.height), paint);
    // Draw the wrapping bar that appears from the left
    canvas.drawRect(Rect.fromLTWH(x - totalWidth, 0, barWidth, size.height), paint);
  }

  @override
  bool shouldRepaint(_LoadingBarPainter oldDelegate) => false;
}
