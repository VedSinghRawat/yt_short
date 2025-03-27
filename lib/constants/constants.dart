const int kAuthRequiredLevel = 3;
const int kMinProgressSyncingDiffInMillis = Duration.millisecondsPerMinute * 1;
const String kIOSAppId = '';

const String kAppStoreBaseUrl = "https://apps.apple.com/app/"; // iOS

const String kPlayStoreBaseUrl = "https://play.google.com/store/apps/details?id="; // Android

const int kMaxStorageSizeMB = 100;

const double kDeleteCacheThresholdMB = kMaxStorageSizeMB * 0.3; // 30%

const genericErrorMessage = 'Something went wrong. Please try again later.';
const internetError = 'No internet connection. Please check your connection and try again.';

const kMaxLevelsPerDay = 2;
