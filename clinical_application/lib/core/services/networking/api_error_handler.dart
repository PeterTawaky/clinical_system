import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'api_error_factory.dart';
import 'api_error_model.dart';
import 'local_status_codes.dart';

class ApiErrorHandler {
  /// Extracts the `detail` field from the server response body.
  /// Falls back to [fallback] if no meaningful detail is present.
  static String _serverDetail(DioException e, String fallback) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        // Pydantic validation error list format
        if (detail is List && detail.isNotEmpty) {
          final messages = detail
              .map((d) => d is Map ? d['msg']?.toString() ?? '' : d.toString())
              .where((s) => s.isNotEmpty)
              .join(', ');
          if (messages.isNotEmpty) return messages;
        }
      }
    } catch (_) {}
    return fallback;
  }

  static ApiErrorModel handle(dynamic e) {
    switch (e) {
      case DioException(:final DioExceptionType type):
        return switch (type) {
          DioExceptionType.connectionError =>
            ApiErrorFactory.noInternetConnection,
          DioExceptionType.connectionTimeout =>
            ApiErrorFactory.connectionTimeout,
          DioExceptionType.sendTimeout => ApiErrorFactory.sendTimeout,
          DioExceptionType.receiveTimeout => ApiErrorFactory.receiveTimeout,
          DioExceptionType.badCertificate => ApiErrorFactory.badCertificate,
          DioExceptionType.badResponse when e.response?.statusCode != null =>
            switch (e.response!.statusCode) {
              400 => ApiErrorModel(
                message: _serverDetail(e, "Something went wrong. Please try again."),
                icon: Icons.error_outline,
                statusCode: 400,
              ),
              401 => ApiErrorModel(
                message: _serverDetail(e, "Please log in to continue."),
                icon: Icons.lock_outline,
                statusCode: 401,
              ),
              403 => ApiErrorModel(
                message: _serverDetail(e, "You don't have permission to access this."),
                icon: Icons.block,
                statusCode: 403,
              ),
              404 => ApiErrorModel(
                message: _serverDetail(e, "The requested item was not found."),
                icon: Icons.search_off,
                statusCode: 404,
              ),
              409 => ApiErrorModel(
                message: _serverDetail(e, "This item already exists."),
                icon: Icons.content_copy,
                statusCode: 409,
              ),
              422 => ApiErrorModel(
                message: _serverDetail(e, "Please check your information and try again."),
                icon: Icons.warning_amber,
                statusCode: 422,
              ),
              429 => ApiErrorModel(
                message: "Please wait a moment before trying again.",
                icon: Icons.timelapse,
                statusCode: 429,
              ),
              500 => ApiErrorModel(
                message: "We're having some trouble. Please try again later.",
                icon: Icons.dangerous,
                statusCode: 500,
              ),
              502 => ApiErrorModel(
                message: "We're experiencing technical issues. Please try again soon.",
                icon: Icons.cloud_off,
                statusCode: 502,
              ),
              503 => ApiErrorModel(
                message: "Our service is currently unavailable. Please check back later.",
                icon: Icons.engineering,
                statusCode: 503,
              ),
              504 => ApiErrorModel(
                message: "Request timed out. Please try again.",
                icon: Icons.timer_off,
                statusCode: 504,
              ),
              _ => ApiErrorFactory.badResponseWithoutCode,
            },
          DioExceptionType.badResponse => ApiErrorModel(
            message: "Something went wrong. Please try again.",
            icon: Icons.warning,
            statusCode: LocalStatusCodes.badResponse,
          ),
          DioExceptionType.cancel => ApiErrorModel(
            message: "Request was cancelled. Please try again.",
            icon: Icons.cancel,
            statusCode: LocalStatusCodes.cancel,
          ),
          DioExceptionType.unknown => ApiErrorModel(
            message: "Something went wrong. Please try again later.",
            icon: Icons.error_outline,
            statusCode: LocalStatusCodes.unknown,
          ),
        };
      case Exception _:
        return ApiErrorFactory.defaultError;
      default:
        return ApiErrorFactory.defaultError;
    }
  }
}
