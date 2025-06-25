import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/dialogue/dialogue_api.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/user/user.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/models/dialogues/dialogues.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dialogue_service.g.dart';

class DialogueService {
  final IDialogueApi dialogueAPI;
  final PrefLang lang;

  DialogueService(this.dialogueAPI, this.lang);

  FutureEither<DialogueDTO> get(String id) async {
    final dialogue = await dialogueAPI.get(id);

    if (dialogue != null) {
      final file = FileService.getFile(PathService.dialogueJson(id));
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(dialogue.toJson()));

      return right(dialogue);
    }

    final file = FileService.getFile(PathService.dialogueJson(id));
    if (!await file.exists()) return left(APIError(message: parseError(DioExceptionType.connectionError, lang)));

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
              final audioFile = FileService.getFile(PathService.dialogueAudio(file.name.replaceAll('.mp3', '')));
              await audioFile.parent.create(recursive: true);
              await audioFile.writeAsBytes(file.content as List<int>);
            }
          }),
        );
      } catch (e) {
        return left(APIError(message: parseError(DioExceptionType.badResponse, lang)));
      }

      return right(null);
    } catch (e) {
      return left(APIError(message: parseError(DioExceptionType.connectionError, lang)));
    }
  }

  bool isDialogueDownloaded(String dialogueId) {
    final file = FileService.getFile(PathService.dialogueAudio(dialogueId));
    return file.existsSync();
  }
}

@riverpod
DialogueService dialogueService(Ref ref) {
  final dialogueAPI = ref.watch(dialogueApiProvider);
  final lang = ref.watch(langControllerProvider);
  return DialogueService(dialogueAPI, lang);
}
