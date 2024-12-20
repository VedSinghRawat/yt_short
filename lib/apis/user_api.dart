import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_config.dart';
import '../models/models.dart';

abstract class IUserAPI {
  Future<void> updateLastViewedVideo(int videoId);
  Future<UserModel?> fetchCurrentUser();
  Future<UserModel?> getCurrentUser(); // Added for compatibility
}

class UserAPI implements IUserAPI {
  final SupabaseClient _supabaseClient = SupabaseConfig.client;

  @override
  Future<UserModel?> fetchCurrentUser() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabaseClient.from('users').select().eq('id', userId).single();

      return UserModel.fromJson(response);
    } catch (e, stackTrace) {
      developer.log('Error getting current user', error: e.toString(), stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // Alias for fetchCurrentUser to maintain compatibility
    return fetchCurrentUser();
  }

  @override
  Future<void> updateLastViewedVideo(int videoId) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) return;

      final user = await _supabaseClient.from('users').update({'at_vid_id': videoId}).eq('id', userId);
    } catch (e, stackTrace) {
      developer.log('Error updating last viewed video', error: e.toString(), stackTrace: stackTrace);
      throw Exception(e.toString());
    }
  }
}

final userAPIProvider = Provider<IUserAPI>((ref) {
  return UserAPI();
});
