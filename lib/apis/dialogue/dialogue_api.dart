import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:myapp/models/dialogues/dialogues.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dialogue_api.g.dart';

abstract class IDialogueApi {
  Future<DialogueDTO?> get(String id);
  Future<Uint8List?> downloadDialogueZip(int zipNum);
}

class DialogueApi implements IDialogueApi {
  final ApiService apiService;

  DialogueApi({required this.apiService});

  @override
  Future<DialogueDTO?> get(String id) async {
    final response = await apiService.getCloudStorageData(endpoint: PathService.dialogueAsset(id, AssetType.data));

    if (response == null) return null;

    final dialogueDTO = DialogueDTO.fromJson({...response.data, 'id': id});

    return dialogueDTO;
  }

  @override
  Future<Uint8List?> downloadDialogueZip(int zipNum) async {
    final response = await apiService.getCloudStorageData(
      endpoint: PathService.dialogueZip(zipNum),
      responseType: ResponseType.bytes,
    );

    return response?.data;
  }
}

@riverpod
DialogueApi dialogueApi(ref) {
  final apiService = ref.read(apiServiceProvider);

  return DialogueApi(apiService: apiService);
}
