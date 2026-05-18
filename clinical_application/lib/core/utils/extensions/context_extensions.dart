import 'dart:io';
import 'dart:math';

import '../app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

extension SizeLayoutExtension on BuildContext {
  // Screen Size
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;

  double get statusBarHeight => padding.top;
  double get bottomPadding => padding.bottom;
  //Scales
  double get scaleWidth => screenWidth / AppConstants.totalFigmaWidth;
  double get scaleHeight => screenHeight / AppConstants.totalFigmaHeight;
  double get scaleText => min(scaleWidth, scaleHeight).clamp(0.8, 1.4);
  TextScaler get textScaler => MediaQuery.of(this).textScaler;

  //Determing Orientation
  Orientation get deviceOrientation => MediaQuery.of(this).orientation;

  bool get isLandscapeOrientation => deviceOrientation == Orientation.landscape;
  bool get isPortraitOrientation => deviceOrientation == Orientation.portrait;

  //Block Size 1%
  double get blockWidth => screenWidth / 100;
  double get blockHeight => screenHeight / 100;

  //Device Type
  bool get isMobileSize => screenWidth < AppConstants.maxMobileWidth;
  bool get isTabletSize =>
      screenWidth >= AppConstants.minTabletWidth &&
      screenWidth < AppConstants.maxTabletWidth;
  bool get isDesktopSize => screenWidth >= AppConstants.minDesktopWidth;
}

extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorsScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDark => theme.brightness == Brightness.dark;
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}

/// System UI (status/nav bars) helpers

extension PlatformExtension on BuildContext {
  bool get isWebPlatform => kIsWeb;
  bool get isDesktopPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// True on mobile targets (Android/iOS), not web.
  bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Per-OS helpers (non-web)
  bool get isWindowsPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  bool get isLinuxPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
  bool get isMacOSPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  bool get isAndroidPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get isIOSPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}

/// Connectivity (same heuristic as your original)
extension ConnectivityExtension on BuildContext {
  Future<bool> get hasInternetConnection async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
