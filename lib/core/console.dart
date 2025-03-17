import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:myapp/core/error/failure.dart';

class Console {
  static final Map<String, Stopwatch> _stopwatches = {};

  static void log(String message, {String? name}) {
    if (!kDebugMode) return;
    dev.log(message, name: name ?? 'Console.log');
  }

  static void error(Failure failure) {
    if (!kDebugMode) return;
    dev.log(
      failure.message,
      error: failure,
      stackTrace: StackTrace.current,
      name: 'Console.error',
      level: 1000,
    );
  }

  static void timeStart(String name) {
    if (!kDebugMode) return;

    final stopwatch = Stopwatch();
    _stopwatches[name] = stopwatch;
    stopwatch.start();

    dev.log(name, name: 'Console.timeStart');
  }

  static void timeEnd(String name) {
    if (!kDebugMode) return;

    final stopwatch = _stopwatches[name];

    if (stopwatch == null) {
      error(Failure(message: 'No stopwatch found for name: $name'));
      return;
    }

    stopwatch.stop();

    final elapsed = stopwatch.elapsedMilliseconds;

    _stopwatches.remove(name);

    dev.log('$name: ${elapsed}ms', name: 'Console.timeEnd');
  }
}
