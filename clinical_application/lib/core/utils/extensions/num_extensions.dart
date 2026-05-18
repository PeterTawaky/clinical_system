import '../app_constants.dart';
import 'context_extensions.dart';
import 'package:flutter/material.dart';

extension ResponsiveNum on num {
  double ac(BuildContext context) =>
      context.textScaler.scale(this * context.scaleText);
  double sp(BuildContext context) => this * context.scaleText;
  double r(BuildContext context) => this * context.scaleText;
  double w(BuildContext context) =>
      this / AppConstants.totalFigmaWidth * context.screenWidth;
  double h(BuildContext context) =>
      this / AppConstants.totalFigmaHeight * context.screenHeight;
}
