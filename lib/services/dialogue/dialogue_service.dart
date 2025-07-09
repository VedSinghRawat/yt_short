import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/dialogue/dialogue_api.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/models/dialogues/dialogues.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dialogue_service.g.dart';

class DialogueService {
  final IDialogueApi dialogueAPI;

  DialogueService(this.dialogueAPI);

  FutureEither<DialogueDTO> get(String id) async {
    final dialogue = await dialogueAPI.get(id);

    if (dialogue != null) {
      final file = FileService.getFile(PathService.dialogueAsset(id, AssetType.data));
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(dialogue.toJson()));

      return right(dialogue);
    }

    final file = FileService.getFile(PathService.dialogueAsset(id, AssetType.data));
    if (!await file.exists()) {
      return left(APIError(message: 'Dialogue not found locally', dioExceptionType: DioExceptionType.connectionError));
    }

    final content = await file.readAsString();
    final jsonMap = jsonDecode(content) as Map<String, dynamic>;

    final localDialogue = DialogueDTO.fromJson(jsonMap);
    return right(localDialogue);
  }

  FutureEither<void> downloadDialogueZip(int zipNum) async {
    try {
      final zipData = await dialogueAPI.downloadDialogueZip(zipNum);
      if (zipData == null) {
        return right(null);
      }

      try {
        // Extract the zip
        final archive = ZipDecoder().decodeBytes(zipData);

        await Future.wait(
          archive.files.map((file) async {
            if (file.isFile && file.name.contains('.mp3')) {
              final audioFile = FileService.getFile(
                PathService.dialogueAsset(file.name.replaceAll('.mp3', ''), AssetType.audio),
              );
              await audioFile.parent.create(recursive: true);
              await audioFile.writeAsBytes(file.content as List<int>);
            }
          }),
        );
      } catch (e) {
        return left(APIError(message: 'Failed to decode zip archive', dioExceptionType: DioExceptionType.badResponse));
      }

      return right(null);
    } catch (e) {
      return left(
        APIError(message: 'Failed to download dialogue zip', dioExceptionType: DioExceptionType.connectionError),
      );
    }
  }

  bool isDialogueDownloaded(String dialogueId) {
    final file = FileService.getFile(PathService.dialogueAsset(dialogueId, AssetType.audio));
    return file.existsSync();
  }
}

@riverpod
DialogueService dialogueService(Ref ref) {
  final dialogueAPI = ref.watch(dialogueApiProvider);
  return DialogueService(dialogueAPI);
}
