import 'package:clinical_application/app/my_app.dart';
import 'package:clinical_application/core/dependencies/di_container.dart';
import 'package:flutter/material.dart';

void main() {
  setupDI();
  runApp(MyApp());
}
