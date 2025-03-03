import 'package:flutter/material.dart';

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
