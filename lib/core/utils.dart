import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

void showErrorSnackBar(BuildContext context, String message) {
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
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

// function to create a random string of length n
String randomString(int n) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  var buffer = '';

  for (var i = 0; i < n; i++) {
    buffer += chars[random.nextInt(chars.length)];
  }

  return buffer;
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

T? stringToEnum<T extends Enum>(String value, List<T> enumValues) {
  try {
    return enumValues.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
}

void tryCall(Function function) {
  try {
    function();
  } catch (e) {
    developer.log('error in tryCall: $e');
  }
}
