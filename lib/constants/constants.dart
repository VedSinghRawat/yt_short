import 'package:myapp/core/controllers/lang_notifier.dart';

class AppConstants {
  // Auth and sync constants
  static const int kAuthRequiredLevel = 1;
  static const int kMinProgressSyncingDiffInMillis = Duration.millisecondsPerMinute * 1;
  static const String kIOSAppId = '';
  static const int kMaxLevelCompletionsPerDay = 1;

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

  // Error messages
  static const connectionError = PrefLangText(
    hindi: 'इंटरनेट काम नहीं कर रहा है। कृपया अपना कनेक्शन जांचें।',
    hinglish: 'Internet kaam nahi kar raha hai. Kripya apna connection check karein.',
  );

  static const connectionTimeout = PrefLangText(
    hindi: 'कनेक्शन में बहुत समय लग रहा है। कृपया दोबारा कोशिश करें।',
    hinglish: 'Connection mein bahut samay lag raha hai. Kripya dobara try karein.',
  );

  static const receiveTimeout = PrefLangText(
    hindi: 'कनेक्ट करने में बहुत समय लग रहा है। कृपया दोबारा प्रयास करें।',
    hinglish: 'Connection mein bahut samay lag raha hai. Kripya dobara try karein.',
  );

  static const sendTimeout = PrefLangText(
    hindi: 'टाइमाउट हो गया। कृपया दोबारा प्रयास करें।',
    hinglish: 'Timeout ho gaya. Kripya dobara try karein.',
  );

  static const badCertificate = PrefLangText(
    hindi: 'सर्वर की पुष्टि नहीं हो सकी। कृपया बाद में फिर से प्रयास करें।',
    hinglish: 'Server verification nahi hua. Kripya thodi der baad try karein.',
  );

  static const cancel = PrefLangText(
    hindi: 'रिक्वेस्ट रद्द कर दी गई। कृपया फिर से कोशिश करें।',
    hinglish: 'Request cancel kar di gayi. Kripya dobara try karein.',
  );

  static const badResponse = PrefLangText(
    hindi: 'सर्वर में कुछ समस्या है। कृपया कुछ समय बाद फिर कोशिश करें।',
    hinglish: 'Server mein problem hai. Kripya kuch samay baad dobara try karein.',
  );

  static const unknownError = PrefLangText(
    hindi: 'कुछ गलत हो गया। कृपया बाद में दोबारा कोशिश करें।',
    hinglish: 'Kuch galat ho gaya. Kripya thodi der baad try karein.',
  );

  static const allLevelsCompleted = PrefLangText(
    hindi: 'फिलहाल के लिए इतने ही लेसन हैं। नए लेसन के लिए कुछ समय बाद फिर से चेक करें!',
    hinglish: 'Filhal ke liye itne hi lessons hain. Naye lessons ke liye kuchh samay baad dobara check karein!',
  );

  static const obstructiveErrorStatus = 599;

  // UI constants
  static const String kViewCloseActionName = 'closeAction';
}
