import 'package:clinical_application/features/users_management/data/datasources/users_remote_datasource.dart';
import 'package:clinical_application/features/users_management/data/models/system_user_model.dart';
import 'package:clinical_application/features/users_management/presentation/cubits/users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit() : super(UsersInitial()) {
    loadUsers();
  }

  final _datasource = UsersRemoteDataSource();

  List<SystemUser> get _currentUsers =>
      switch (state) {
        UsersLoaded s => s.users,
        UsersActionLoading s => s.users,
        UsersError s => s.users,
        _ => [],
      };

  Future<void> loadUsers() async {
    emit(UsersLoading());
    try {
      final users = await _datasource.getUsers();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UsersError(_errorMessage(e), []));
    }
  }

  Future<void> addUser({
    required String username,
    required String password,
    required UserRole role,
  }) async {
    final trimmed = username.trim();
    final current = _currentUsers;
    emit(UsersActionLoading(current));
    try {
      await _datasource.createUser(SystemUser(
        id: trimmed,
        username: trimmed,
        password: password,
        role: role,
      ));
      await _refreshAfterAction();
    } catch (e) {
      emit(UsersError(_errorMessage(e), current));
      emit(UsersLoaded(current));
    }
  }

  Future<void> editUser({
    required String id,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    final current = _currentUsers;
    emit(UsersActionLoading(current));
    try {
      await _datasource.updateUser(
        username: id, // id == username (API primary key)
        password: password,
        role: role,
      );
      await _refreshAfterAction();
    } catch (e) {
      emit(UsersError(_errorMessage(e), current));
      emit(UsersLoaded(current));
    }
  }

  Future<void> deleteUser(String id) async {
    final current = _currentUsers;
    emit(UsersActionLoading(current));
    try {
      await _datasource.deleteUser(id);
      await _refreshAfterAction();
    } catch (e) {
      emit(UsersError(_errorMessage(e), current));
      emit(UsersLoaded(current));
    }
  }

  Future<void> _refreshAfterAction() async {
    final users = await _datasource.getUsers();
    emit(UsersLoaded(users));
  }

  String _errorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('409') || msg.contains('already exists')) {
      return 'اسم المستخدم موجود مسبقاً';
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return 'المستخدم غير موجود';
    }
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'تعذّر الاتصال بالخادم';
    }
    return 'حدث خطأ، يرجى المحاولة مجدداً';
  }
}
