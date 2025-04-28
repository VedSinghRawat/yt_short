import 'package:flutter/material.dart';

class LoadingRefreshIcon extends StatefulWidget {
  final bool isLoading;
  final IconData icon;
  final Duration duration;
  final VoidCallback? onTap;

  const LoadingRefreshIcon({
    super.key,
    required this.isLoading,
    this.icon = Icons.refresh,
    this.duration = const Duration(seconds: 1),
    this.onTap,
  });

  @override
  State<LoadingRefreshIcon> createState() => _LoadingRefreshIconState();
}

class _LoadingRefreshIconState extends State<LoadingRefreshIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LoadingRefreshIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isLoading && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return RotationTransition(
        turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
        child: Icon(widget.icon, color: Theme.of(context).colorScheme.onSurface),
      );
    } else {
      return GestureDetector(
        onTap: widget.onTap,
        child: Icon(widget.icon, color: Theme.of(context).colorScheme.onSurface),
      );
    }
  }
}
