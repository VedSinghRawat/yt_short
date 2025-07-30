import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum Screen { mobile, tablet, largeTablet }

class ResponsivenessService {
  final BuildContext _context;

  ResponsivenessService(this._context);

  Screen getScreenType() {
    return getScreenTypeStatic(View.of(_context));
  }

  // Method to check if current orientation is landscape
  bool isLandscape() {
    final orientation = MediaQuery.of(_context).orientation;
    return orientation == Orientation.landscape;
  }

  // Method to check if device is tablet in landscape mode
  bool isTabletLandscape() {
    return getScreenType() != Screen.mobile && isLandscape();
  }

  // Method to get responsive numeric values based on device type
  double getResponsiveValues({required double mobile, required double tablet, required double largeTablet}) {
    final screenType = getScreenType();
    switch (screenType) {
      case Screen.largeTablet:
        return largeTablet;
      case Screen.tablet:
        return tablet;
      case Screen.mobile:
        return mobile;
    }
  }

  // Method to set orientation based on device type
  Future<void> setProperOrientation() async {
    try {
      if (getScreenType() == Screen.mobile) {
        // Lock mobile to portrait only
        await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      } else {
        // Allow all orientations for tablets
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } catch (e) {
      // Fallback: if there's any error, lock to portrait for safety
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
  }

  // Static method to get screen type without context (useful for main.dart style detection)
  static Screen getScreenTypeStatic(FlutterView win) {
    final shortestSide = win.physicalSize.shortestSide / win.devicePixelRatio;

    if (shortestSide >= 800) {
      return Screen.largeTablet;
    } else if (shortestSide >= 600) {
      return Screen.tablet;
    } else {
      return Screen.mobile;
    }
  }

  // Method to force portrait mode (useful for certain screens)
  static Future<void> forcePortrait() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }
}
