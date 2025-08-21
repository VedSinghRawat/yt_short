import 'package:flutter/material.dart';
import '../../services/responsiveness/responsiveness_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
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
    final responsivenessService = ResponsivenessService(context);

    // Responsive image width
    final imageWidth = responsivenessService.getResponsiveValues(mobile: 150.0, tablet: 200.0, largeTablet: 250.0);

    // Responsive loading bar width
    final loadingBarWidth = responsivenessService.getResponsiveValues(mobile: 200.0, tablet: 300.0, largeTablet: 400.0);

    // Responsive loading bar height
    final loadingBarHeight = responsivenessService.getResponsiveValues(mobile: 8.0, tablet: 10.0, largeTablet: 12.0);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/img/logo.png', width: imageWidth),
            const SizedBox(height: 40),
            CustomPaint(
              size: Size(loadingBarWidth, loadingBarHeight),
              painter: _LoadingBarPainter(animation: _controller),
            ),
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
