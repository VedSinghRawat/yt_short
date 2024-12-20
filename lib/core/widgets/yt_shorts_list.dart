import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/yt_short.dart';

class YoutubeShortsList extends StatefulWidget {
  final List<String> ytIds;
  final Function(int index)? onVideoChange;

  const YoutubeShortsList({
    super.key,
    required this.ytIds,
    this.onVideoChange,
  });

  @override
  State<YoutubeShortsList> createState() => _YoutubeShortListState();
}

class _YoutubeShortListState extends State<YoutubeShortsList> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    int newPage = _pageController.page?.round() ?? 0;
    if (newPage == _currentPage) return;

    setState(() => _currentPage = newPage);
    widget.onVideoChange?.call(newPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.ytIds.length,
      scrollDirection: Axis.vertical,
      itemBuilder: (context, index) {
        return Center(
          child: YoutubeShort(
            key: ValueKey(widget.ytIds[index]),
            videoId: widget.ytIds[index],
          ),
        );
      },
    );
  }
}
