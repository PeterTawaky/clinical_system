import 'package:flutter/material.dart';
import 'api_error_model.dart';
import 'local_status_codes.dart';

class ApiErrorFactory {
  static ApiErrorModel get defaultError => ApiErrorModel(
    message: "Something went wrong",
    icon: Icons.error,
    statusCode: LocalStatusCodes.defaultError,
  );
  static ApiErrorModel get badResponseWithoutCode => ApiErrorModel(
    //when the server doesn't send status code in the response
    message: "Something went wrong",
    icon: Icons.error,
    statusCode: LocalStatusCodes.badResponse,
  );
  static ApiErrorModel get noInternetConnection => ApiErrorModel(
    message: "Server Connection Error",
    icon: Icons.wifi_off,
    statusCode: LocalStatusCodes.connectionError,
  );
  static ApiErrorModel get connectionTimeout => ApiErrorModel(
    message: "Connection timed out. Please try again.",
    icon: Icons.timer_off,
    statusCode: LocalStatusCodes.connectionTimeout,
  );
  static ApiErrorModel get sendTimeout => ApiErrorModel(
    message: "Couldn't send your request. Please try again.",
    icon: Icons.send,
    statusCode: LocalStatusCodes.sendTimeout,
  );
  static ApiErrorModel get receiveTimeout => ApiErrorModel(
    message: "Taking too long to load. Please try again later.",
    icon: Icons.downloading,
    statusCode: LocalStatusCodes.receiveTimeout,
  );
  static ApiErrorModel get badCertificate => ApiErrorModel(
    message: "Security issue detected. Please try again later.",
    icon: Icons.security,
    statusCode: LocalStatusCodes.badCertificate,
  );
}
