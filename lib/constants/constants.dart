const int kAuthRequiredLevel = 1;
const int kMinProgressSyncingDiffInMillis = Duration.millisecondsPerMinute * 1;
const String kIOSAppId = '';

const String kAppStoreBaseUrl = "https://apps.apple.com/app/"; // iOS

const String kPlayStoreBaseUrl = "https://play.google.com/store/apps/details?id="; // Android

const int kMaxStorageSizeBytes = 100 * 1024 * 1024; // 100mb

const double kDeleteCacheThreshold = kMaxStorageSizeBytes * 0.3; // 30%

const kMaxPreviousLevelsToKeep = 1;
const kMaxNextLevelsToKeep = 2;

// errors

const connectionErrorMsg = 'Internet not working. Please check your connection.';
const connectionTimeoutMsg = 'Taking too long to connect. Please try again.';
const receiveTimeoutMsg = 'Taking too long to respond. Please try again.';
const sendTimeoutMsg = 'Taking too long to send request. Please try again.';
const badCertificateMsg = 'Could not verify server. Please try again later.';
const cancelMsg = 'Request cancelled. Please try again.';
const badResponseMsg = 'Server problem. Please try again after some time.';
const unknownErrorMsg = 'Something went wrong. Please try again later.';
const videoPlayerError = 'There was some problem while playing this video, you can skip it now.';
const kMaxLevelCompletionsPerDay = 1;
