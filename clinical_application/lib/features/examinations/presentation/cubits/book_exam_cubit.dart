import 'package:clinical_application/features/examinations/data/datasources/examinations_datasource.dart';
import 'package:clinical_application/features/examinations/presentation/cubits/book_exam_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookExamCubit extends Cubit<BookExamState> {
  BookExamCubit() : super(BookExamInitial()) {
    load();
  }

  final _ds = ExaminationsDatasource();

  Future<void> load() async {
    emit(BookExamLoading());
    try {
      final results = await Future.wait([
        _ds.getDoctors(),
        _ds.getBranches(),
        _ds.getSpecialties(),
      ]);
      emit(BookExamLoaded(
        doctors: results[0] as dynamic,
        branches: results[1] as dynamic,
        specialties: results[2] as dynamic,
      ));
    } catch (e) {
      emit(BookExamError(_msg(e)));
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
