import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:myapp/core/error/failure.dart';
import 'dart:math';

class Console {
  static final Map<String, Stopwatch> _stopwatches = {};
  static final Map<String, String> _colorTags = {};
  static final List<String> _colorEmojis = [
    '🟥',
    '🟧',
    '🟨',
    '🟩',
    '🟦',
    '🟪',
    '⬛',
    '🟫',
    '🔵',
    '🔴',
    '🟢',
  ];

  static String _getOrCreateColorTag(String name) {
    if (_colorTags.containsKey(name)) return _colorTags[name]!;

    final random = Random();
    final color = _colorEmojis[random.nextInt(_colorEmojis.length)];
    _colorTags[name] = color;
    return color;
  }

  static void log(String message, {String? name}) {
    if (!kDebugMode) return;
    dev.log(message, name: name ?? '[log] Console');
  }

  static void time(String message, {String? name}) {
    if (!kDebugMode) return;
    dev.log('$message time: ${DateTime.now()}', name: name ?? '[log] Console');
  }

  static void error(Failure failure, StackTrace stackTrace) {
    if (!kDebugMode) return;
    dev.log(
      failure.message,
      error: failure,
      stackTrace: stackTrace,
      name: '[log] error',
      level: 1000,
    );
  }

  static void timeStart(String name) {
    if (!kDebugMode) return;

    final stopwatch = Stopwatch();
    _stopwatches[name] = stopwatch;
    stopwatch.start();

    final tag = _getOrCreateColorTag(name);
    dev.log('$tag $name started', name: '[log] timeStart');
  }

  static void timeEnd(String name) {
    if (!kDebugMode) return;

    final stopwatch = _stopwatches[name];

    if (stopwatch == null) {
      error(
        Failure(message: 'No stopwatch found for name: $name'),
        StackTrace.current,
      );
      return;
    }

    stopwatch.stop();

    final elapsed = stopwatch.elapsedMilliseconds;
    final tag = _getOrCreateColorTag(name);
    _stopwatches.remove(name);
    _colorTags.remove(name);

    dev.log('$tag $name ended: ${elapsed}ms', name: '[log] timeEnd');
  }
}
