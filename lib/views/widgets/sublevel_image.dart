import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/path/path_service.dart';

class SubLevelImage extends ConsumerWidget {
  const SubLevelImage({super.key, required this.levelId, required this.sublevelId});

  final String levelId;
  final String sublevelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = MediaQuery.of(context).size.height * 0.25;
    return Image.file(
      FileService.getFile(PathService.sublevelAsset(levelId, sublevelId, AssetType.image)),
      fit: BoxFit.cover,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        final urls =
            [BaseUrl.cloudflare, BaseUrl.s3]
                .map(
                  (url) => ref
                      .read(sublevelControllerProvider.notifier)
                      .getAssetUrl(levelId, sublevelId, AssetType.image, url),
                )
                .toList();

        return Image.network(
          urls[0],
          fit: BoxFit.cover,
          height: height,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          },
          errorBuilder: (context, error, stackTrace) {
            return Image.network(
              urls[1],
              fit: BoxFit.cover,
              height: height,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              },
              errorBuilder: (context, error, stackTrace) {
                developer.log('error is $error, $urls');
                return const Center(child: Icon(Icons.image, size: 40, color: Colors.grey));
              },
            );
          },
        );
      },
    );
  }
}
