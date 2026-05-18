import 'package:clinical_application/features/users_management/data/models/system_user_model.dart';

sealed class UsersState {}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<SystemUser> users;
  UsersLoaded(this.users);
}

class UsersActionLoading extends UsersState {
  final List<SystemUser> users; // keep list visible during action
  UsersActionLoading(this.users);
}

class UsersError extends UsersState {
  final String message;
  final List<SystemUser> users; // keep list visible after error
  UsersError(this.message, this.users);
}
