import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
import 'package:myapp/core/error/failure.dart';

/// Start of Selection

void _showCustomSnackBar(
  BuildContext context, {
  required String message,
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
}) {
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: () => messenger.hideCurrentSnackBar(),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
      backgroundColor: backgroundColor ?? Colors.grey[800],
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  _showCustomSnackBar(
    context,
    message: message,
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 4),
    icon: Icons.error_outline,
  );
}

void showSnackBar(BuildContext context, String text) {
  _showCustomSnackBar(
    context,
    message: text,
    backgroundColor: Colors.blue,
    icon: Icons.info_outline,
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  _showCustomSnackBar(
    context,
    message: message,
    backgroundColor: Colors.green,
    icon: Icons.check_circle_outline,
  );
}

// check if levelA is after levelB if levelA is after levelB then return true
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
String parseError(DioExceptionType? type, Ref ref) {
  if (type == null) return ref.read(langProvider.notifier).prefLangText(AppConstants.unknownError);

  final e = switch (type) {
    DioExceptionType.connectionError => AppConstants.connectionError,
    DioExceptionType.connectionTimeout => AppConstants.connectionTimeout,
    DioExceptionType.receiveTimeout => AppConstants.receiveTimeout,
    DioExceptionType.sendTimeout => AppConstants.sendTimeout,
    DioExceptionType.badCertificate => AppConstants.badCertificate,
    DioExceptionType.cancel => AppConstants.cancel,
    DioExceptionType.badResponse => AppConstants.badResponse,
    DioExceptionType.unknown => AppConstants.unknownError,
  };

  return ref.read(langProvider.notifier).prefLangText(e);
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
