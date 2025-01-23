import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

abstract class IUserAPI {
  Future<void> sync(int videoId);
  Future<UserModel?> getCurrentUser();
}

class UserAPI implements IUserAPI {
  final GoogleSignIn _googleSignIn;

  UserAPI(this._googleSignIn);

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return null;

      return UserModel(
        id: googleUser.id,
        email: googleUser.email,
        level: 1,
        subLevel: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log('Error getting current user', error: e.toString(), stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> sync(int videoId) async {}
}

final userAPIProvider = Provider<IUserAPI>((ref) {
  final googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  return UserAPI(googleSignIn);
});
