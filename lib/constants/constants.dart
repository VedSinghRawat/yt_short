const int kAuthRequiredLevel = 3;
const int kSubLevelAPIBuffer = 3;
const int kMinProgressSyncingDiffInMillis = Duration.millisecondsPerMinute * 1;
const String kIOSAppId = '';

const String kAppStoreBaseUrl = "https://apps.apple.com/app/"; // iOS

const String kPlayStoreBaseUrl = "https://play.google.com/store/apps/details?id="; // Android

const int kMaxStorageSizeMB = 50;

const double kDeleteCacheThresholdMB = kMaxStorageSizeMB * 0.3; // 30%
