import 'package:clinical_application/core/services/networking/dio_consumer.dart';
import 'package:clinical_application/features/actions_history/data/models/action_model.dart';

class ActionsRemoteDataSource {
  final DioConsumer _dio;

  ActionsRemoteDataSource() : _dio = DioConsumer();

  Future<List<ActionModel>> getActions({String? username}) async {
    final response = await _dio.get(
      '/actions_history',
      queryParameters: username != null ? {'username': username} : null,
    );
    final list = response as List<dynamic>;
    return list
        .map((e) => ActionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
