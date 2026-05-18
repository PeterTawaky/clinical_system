import 'package:clinical_application/core/services/app_session.dart';
import 'package:clinical_application/core/services/networking/dio_consumer.dart';

/// Fire-and-forget action logger.
/// Call [ActionLogger.log] anywhere after a meaningful user action.
/// Never throws — logging failures are silently swallowed so they never
/// interrupt the user flow.
class ActionLogger {
  ActionLogger._();

  static final DioConsumer _dio = DioConsumer();

  static Future<void> log(String description) async {
    final username = AppSession.currentUsername;
    if (username == null) return;
    try {
      await _dio.post(
        '/actions_history',
        data: {'username': username, 'action_description': description},
      );
    } catch (_) {
      // Logging must never break the app
    }
  }
}
