import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'profile',
  ],
  serverClientId: dotenv.env['GOOGLE_SERVER_ID'],
);
