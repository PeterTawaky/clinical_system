import 'package:clinical_application/features/examinations/data/datasources/examinations_datasource.dart';
import 'package:clinical_application/features/examinations/presentation/cubits/add_exam_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddExamCubit extends Cubit<AddExamState> {
  AddExamCubit() : super(AddExamInitial()) {
    _loadPatients();
  }

  final _ds = ExaminationsDatasource();

  Future<void> _loadPatients() async {
    emit(AddExamLoadingPatients());
    try {
      final patients = await _ds.getPatients();
      emit(AddExamReady(patients: patients));
    } catch (_) {
      emit(AddExamReady(patients: []));
    }
  }

  Future<void> submit({
    required int doctorId,
    required String patientName,
    required String phone,
    String? birthDate,
    required int serviceId,
    required int branchId,
    required String examDate,
    required String examNumber,
  }) async {
    emit(AddExamSubmitting());
    try {
      await _ds.generateExamination(
        doctorId: doctorId,
        patientName: patientName,
        phone: phone,
        birthDate: birthDate,
        serviceId: serviceId,
        branchId: branchId,
        examDate: examDate,
        examNumber: examNumber,
      );
      emit(AddExamSuccess());
    } catch (e) {
      final msg = e.toString().contains('detail')
          ? _extractDetail(e.toString())
          : 'حدث خطأ أثناء حجز الكشف';
      emit(AddExamError(msg));
    }
  }

  String _extractDetail(String msg) {
    final start = msg.indexOf('"detail":');
    if (start == -1) return 'حدث خطأ أثناء حجز الكشف';
    final sub = msg.substring(start + 9).trim();
    return sub.replaceAll(RegExp(r'["\}]'), '').trim();
  }
}
