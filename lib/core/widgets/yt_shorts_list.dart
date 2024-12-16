import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/yt_short.dart';

class YoutubeShortsList extends StatelessWidget {
  final List<String> videoIds;

  const YoutubeShortsList({super.key, required this.videoIds});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: videoIds.length, 
      itemBuilder: (context, index) => Center(
        child: YoutubeShort(
          videoId: videoIds[index],
        ),
      ),
      scrollDirection: Axis.vertical, // For vertical swiping
    );
  }
}
