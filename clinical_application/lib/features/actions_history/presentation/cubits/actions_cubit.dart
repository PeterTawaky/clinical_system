import 'package:clinical_application/core/services/app_session.dart';
import 'package:clinical_application/features/actions_history/data/datasources/actions_remote_datasource.dart';
import 'package:clinical_application/features/actions_history/presentation/cubits/actions_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActionsCubit extends Cubit<ActionsState> {
  ActionsCubit() : super(ActionsInitial()) {
    loadAll();
  }

  final _datasource = ActionsRemoteDataSource();

  Future<void> loadAll() async {
    emit(ActionsLoading());
    try {
      final actions = await _datasource.getActions();
      emit(ActionsLoaded(actions));
    } catch (_) {
      emit(ActionsError('تعذّر تحميل السجل، يرجى المحاولة مجدداً'));
    }
  }

  Future<void> loadMine() async {
    final username = AppSession.currentUsername;
    if (username == null) return;
    emit(ActionsLoading());
    try {
      final actions = await _datasource.getActions(username: username);
      emit(ActionsLoaded(actions, showingMineOnly: true));
    } catch (_) {
      emit(ActionsError('تعذّر تحميل السجل، يرجى المحاولة مجدداً'));
    }
  }
}
