import 'package:bloc/bloc.dart';
import 'package:clinical_application/core/services/networking/api_consumer.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final ApiConsumer api;

  LoginCubit(this.api) : super(LoginInitial());

  Future<void> login({required String username, required String password}) async {
    emit(LoginLoading());
    try {
      final response = await api.get('/system_users');
      final users = (response as List).cast<Map<String, dynamic>>();
      final match = users
          .where((u) => u['username'] == username && u['password'] == password)
          .toList();

      if (match.isEmpty) {
        emit(LoginFailure('اسم المستخدم أو كلمة المرور غير صحيحة'));
      } else {
        emit(LoginSuccess(
          username: match.first['username'] as String,
          role: match.first['role'] as String,
        ));
      }
    } catch (_) {
      emit(LoginFailure('حدث خطأ في الاتصال، يرجى المحاولة مرة أخرى'));
    }
  }
}
