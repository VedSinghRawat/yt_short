import 'package:dio/dio.dart';
import 'package:myapp/models/user/user.dart';

class AppConstants {
  // Auth and sync constants
  static const int kMinProgressSyncingDiffInMillis = Duration.millisecondsPerMinute * 1;
  static const String kIOSAppId = '';
  static const int kMaxLevelCompletionsPerDay = 2;

  // Storage constants
  static const int kMaxStorageSizeBytes = 100 * 1024 * 1024; // 100mb
  static const double kDeleteCacheThreshold = kMaxStorageSizeBytes * 0.3; // 30%

  // Level management constants
  static const int kMaxPreviousLevelsToKeep = 1;
  static const int kMaxNextLevelsToKeep = 2;

  // +1 for current level
  static const int kProtectedIdsLength = kMaxNextLevelsToKeep + kMaxPreviousLevelsToKeep + 1;

  // Referrer constants
  static const String kDefaultReferrer = "utm_source=google-play&utm_medium=organic";

  static String kDioErrorMessages(DioExceptionType? eType, PrefLang lang) {
    return switch (eType) {
      DioExceptionType.connectionError => switch (lang) {
        PrefLang.hindi => 'इंटरनेट काम नहीं कर रहा है। कृपया अपना कनेक्शन जांचें।',
        PrefLang.hinglish => 'Internet kaam nahi kar raha hai. Kripya apna connection check karein.',
      },

      DioExceptionType.connectionTimeout => switch (lang) {
        PrefLang.hindi => 'कनेक्शन में बहुत समय लग रहा है। कृपया दोबारा कोशिश करें।',
        PrefLang.hinglish => 'Connection mein bahut samay lag raha hai. Kripya dobara try karein.',
      },

      DioExceptionType.receiveTimeout => switch (lang) {
        PrefLang.hindi => 'कनेक्ट करने में बहुत समय लग रहा है। कृपया दोबारा प्रयास करें।',
        PrefLang.hinglish => 'Connection mein bahut samay lag raha hai. Kripya dobara try karein.',
      },

      DioExceptionType.sendTimeout => switch (lang) {
        PrefLang.hindi => 'टाइमाउट हो गया। कृपया दोबारा प्रयास करें।',
        PrefLang.hinglish => 'Timeout ho gaya. Kripya dobara try karein.',
      },

      DioExceptionType.badCertificate => switch (lang) {
        PrefLang.hindi => 'सर्वर की पुष्टि नहीं हो सकी। कृपया बाद में फिर से प्रयास करें।',
        PrefLang.hinglish => 'Server verification nahi hua. Kripya thodi der baad try karein.',
      },

      DioExceptionType.cancel => switch (lang) {
        PrefLang.hindi => 'रिक्वेस्ट रद्द कर दी गई। कृपया फिर से कोशिश करें।',
        PrefLang.hinglish => 'Request cancel kar di gayi. Kripya dobara try karein.',
      },

      DioExceptionType.badResponse => switch (lang) {
        PrefLang.hindi => 'सर्वर में कुछ समस्या है। कृपया कुछ समय बाद फिर कोशिश करें।',
        PrefLang.hinglish => 'Server mein problem hai. Kripya kuch samay baad dobara try karein.',
      },

      DioExceptionType.unknown => switch (lang) {
        PrefLang.hindi => 'कुछ गलत हो गया। कृपया बाद में दोबारा कोशिश करें।',
        PrefLang.hinglish => 'Kuch galat ho gaya. Kripya thodi der baad try karein.',
      },

      null => switch (lang) {
        PrefLang.hindi => 'कुछ गलत हो गया। कृपया बाद में दोबारा कोशिश करें।',
        PrefLang.hinglish => 'Kuch galat ho gaya. Kripya thodi der baad try karein.',
      },
    };
  }

  static String allLevelsCompleted(PrefLang lang) {
    return switch (lang) {
      PrefLang.hindi => 'फिलहाल के लिए इतने ही लेसन हैं। नए लेसन के लिए कुछ समय बाद फिर से चेक करें!',
      PrefLang.hinglish =>
        'Filhal ke liye itne hi lessons hain. Naye lessons ke liye kuchh samay baad dobara check karein!',
    };
  }

  static const obstructiveErrorStatus = 599;

  // UI constants
  static const String kViewCloseActionName = 'closeAction';

  static const int kMaxHttpStatusCode = 599;

  static const int kMaxAfterLevels = 2;
  static const int kMaxBeforeLevels = 1;

  static const String kResetStateError = 'resetStateError';
}
