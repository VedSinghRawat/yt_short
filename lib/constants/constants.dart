const int kAuthRequiredLevel = 3;
const int kMinProgressSyncingDiffInMillis = Duration.millisecondsPerMinute * 1;
const String kIOSAppId = '';

const String kAppStoreBaseUrl = "https://apps.apple.com/app/"; // iOS

const String kPlayStoreBaseUrl = "https://play.google.com/store/apps/details?id="; // Android

const int kMaxStorageSizeBytes = 100 * 1024 * 1024;

const double kDeleteCacheThreshold = kMaxStorageSizeBytes * 0.3; // 30%

const genericErrorMessage = 'Something went wrong. Please try again later.';
const internetError = 'No internet connection. Please check your connection and try again.';

const kMaxPreviousLevelsToKeep = 1;
const kMaxNextLevelsToKeep = 2;
