import 'package:clinical_application/features/examinations/data/datasources/examinations_datasource.dart';
import 'package:clinical_application/features/examinations/presentation/cubits/exams_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExamsListCubit extends Cubit<ExamsListState> {
  ExamsListCubit(this._status) : super(ExamsListInitial());

  final String _status;
  final _ds = ExaminationsDatasource();

  Future<void> load({String? date}) async {
    emit(ExamsListLoading());
    try {
      final exams = await _ds.getExaminations(status: _status, date: date);
      emit(ExamsListLoaded(exams: exams));
    } catch (e) {
      emit(ExamsListError(_msg(e)));
    }
  }

  Future<void> confirmExam(int examId, String username, {String? date}) async {
    final current = state;
    if (current is! ExamsListLoaded) return;
    emit(ExamsListActionLoading(exams: current.exams));
    try {
      await _ds.confirmExam(examId, username);
      await load(date: date);
    } catch (e) {
      emit(ExamsListLoaded(exams: current.exams));
      rethrow;
    }
  }

  Future<void> cancelExam(int examId, {String? date}) async {
    final current = state;
    if (current is! ExamsListLoaded) return;
    emit(ExamsListActionLoading(exams: current.exams));
    try {
      await _ds.cancelExam(examId);
      await load(date: date);
    } catch (e) {
      emit(ExamsListLoaded(exams: current.exams));
      rethrow;
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('connection')) {
      return 'تعذّر الاتصال بالخادم';
    }
    return 'حدث خطأ، يرجى المحاولة مجدداً';
  }
}
