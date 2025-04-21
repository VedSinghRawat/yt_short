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
  static const String connectionErrorMsg = 'Internet not working. Please check your connection.';
  static const String connectionTimeoutMsg = 'Taking too long to connect. Please try again.';
  static const String receiveTimeoutMsg = 'Taking too long to respond. Please try again.';
  static const String sendTimeoutMsg = 'Taking too long to send request. Please try again.';
  static const String badCertificateMsg = 'Could not verify server. Please try again later.';
  static const String cancelMsg = 'Request cancelled. Please try again.';
  static const String badResponseMsg = 'Server problem. Please try again after some time.';
  static const String unknownErrorMsg = 'Something went wrong. Please try again later.';
  static const String videoPlayerError =
      'There was some problem while playing this video, you can skip it now.';

  // UI constants
  static const String kViewCloseActionName = 'closeAction';
}
