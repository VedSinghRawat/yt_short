import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/error/failure.dart';

void showErrorSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;

  // Remove mounted check since ScaffoldMessenger handles this internally
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
    ),
  );
}

void showSnackBar(BuildContext context, String text) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
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
typedef FutureEither<T> = Future<Either<Failure, T>>;

typedef FutureVoid = FutureEither<void>;

final dioConnectionErrors = {DioExceptionType.connectionError};

/// Return user friendly error message based on dio exception type
String parseError(DioExceptionType? type) {
  if (type == null) return AppConstants.unknownErrorMsg;

  return switch (type) {
    DioExceptionType.connectionError => AppConstants.connectionErrorMsg,
    DioExceptionType.connectionTimeout => AppConstants.connectionTimeoutMsg,
    DioExceptionType.receiveTimeout => AppConstants.receiveTimeoutMsg,
    DioExceptionType.sendTimeout => AppConstants.sendTimeoutMsg,
    DioExceptionType.badCertificate => AppConstants.badCertificateMsg,
    DioExceptionType.cancel => AppConstants.cancelMsg,
    DioExceptionType.badResponse => AppConstants.badResponseMsg,
    DioExceptionType.unknown => AppConstants.unknownErrorMsg,
  };
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
