import 'package:clinical_application/core/services/networking/dio_consumer.dart';
import 'package:clinical_application/features/users_management/data/models/system_user_model.dart';

class UsersRemoteDataSource {
  final DioConsumer _dio;

  UsersRemoteDataSource() : _dio = DioConsumer();

  Future<List<SystemUser>> getUsers() async {
    final response = await _dio.get('/system_users');
    final list = response as List<dynamic>;
    return list
        .map((e) => SystemUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createUser(SystemUser user) async {
    await _dio.post(
      '/system_users',
      data: {
        'username': user.username,
        'role': user.role.apiValue,
        'password': user.password,
      },
    );
  }

  Future<void> updateUser({
    required String username,
    required String password,
    required UserRole role,
  }) async {
    await _dio.put(
      '/system_users/$username',
      data: {'role': role.apiValue, 'password': password},
    );
  }

  Future<void> deleteUser(String username) async {
    await _dio.delete('/system_users/$username');
  }
}
