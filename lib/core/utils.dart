import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/models/user/user.dart';
import 'package:myapp/views/widgets/lang_text.dart';

enum SnackBarType { error, info, success }

void showSnackBar(
  BuildContext context, {
  required String message,
  SnackBarType type = SnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  if (!context.mounted) return;

  final (backgroundColor, icon) = switch (type) {
    SnackBarType.error => (Colors.red, Icons.error_outline),
    SnackBarType.info => (Colors.blue, Icons.info_outline),
    SnackBarType.success => (Colors.green, Icons.check_circle_outline),
  };

  final messenger = ScaffoldMessenger.of(context);
  final deviceHeight = MediaQuery.of(context).size.height;

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: LangText.bodyText(
                text: message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
            const VerticalDivider(color: Colors.white, thickness: 1),
            IconButton(onPressed: () => messenger.clearSnackBars(), icon: const Icon(Icons.close, color: Colors.white)),
          ],
        ),
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: EdgeInsets.only(bottom: deviceHeight - 200, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.only(left: 10, right: 0, top: 10, bottom: 10),
    ),
  );
}

bool isLevelAfter(int levelA, int subLevelA, int levelB, int subLevelB) {
  return levelA > levelB || (levelA == levelB && subLevelA > subLevelB);
}

bool isLevelEqual(int levelA, int subLevelA, int levelB, int subLevelB) {
  return levelA == levelB && subLevelA == subLevelB;
}

num getMax(List<num?> numbers) {
  if (numbers.isEmpty) return 0;

  num maxVal = numbers[0] ?? 0;
  for (var i = 1; i < numbers.length; i++) {
    if (numbers[i] != null && numbers[i]! > maxVal) {
      maxVal = numbers[i]!;
    }
  }
  return maxVal;
}

// type alias for fpdart
typedef FutureEither<T> = Future<Either<APIError, T>>;

typedef FutureVoid = FutureEither<void>;

final dioConnectionErrors = {DioExceptionType.connectionError};

/// Return user friendly error message based on dio exception type
String parseError(DioExceptionType? type, PrefLang lang) {
  return AppConstants.kDioErrorMessages(type, lang);
}

bool isPrimitive(dynamic value) {
  return value is String || value is int || value is double || value is bool;
}

bool isListOfPrimitives(dynamic value) {
  return value is List && value.every(isPrimitive);
}

/// Formats a duration in seconds into MM:SS string format.
String formatDurationMMSS(double seconds) {
  final duration = Duration(seconds: seconds.toInt());
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final secs = twoDigits(duration.inSeconds.remainder(60));
  return '$minutes:$secs';
}

bool hasToJson<T>(T o) {
  try {
    (o as dynamic).toJson();
    return true;
  } on NoSuchMethodError {
    return false;
  }
}

String choose({required String hindi, required String hinglish, required PrefLang lang}) {
  return switch (lang) {
    PrefLang.hindi => hindi,
    PrefLang.hinglish => hinglish,
  };
}
