import 'package:flutter/material.dart';

class ResponsivenessService {
  final BuildContext _context;

  ResponsivenessService(this._context);

  // Helper method to determine if screen is tablet size
  bool _isTablet() {
    final size = MediaQuery.of(_context).size;
    final shortestSide = size.shortestSide;
    return shortestSide >= 600; // Standard tablet breakpoint
  }

  // Helper method to determine if screen is a large tablet
  bool _isLargeTablet() {
    final size = MediaQuery.of(_context).size;
    final shortestSide = size.shortestSide;
    return shortestSide >= 800; // Large tablet breakpoint
  }

  // Method to get responsive numeric values based on device type
  double getResponsiveValues({required double mobile, required double tablet, required double largeTablet}) {
    if (_isLargeTablet()) {
      return largeTablet;
    } else if (_isTablet()) {
      return tablet;
    } else {
      return mobile;
    }
  }
}
