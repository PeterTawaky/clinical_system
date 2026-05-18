import 'package:clinical_application/features/doctors/data/datasources/doctors_view_datasource.dart';
import 'package:clinical_application/features/doctors/presentation/cubits/doctors_view_state.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoctorsViewCubit extends Cubit<DoctorsViewState> {
  DoctorsViewCubit() : super(DoctorsViewInitial()) {
    load();
  }

  final _datasource = DoctorsViewDataSource();

  Future<void> load() async {
    emit(DoctorsViewLoading());
    try {
      final results = await Future.wait([
        _datasource.getDoctors(),
        _datasource.getBranches(),
        _datasource.getSpecialties(),
      ]);
      emit(DoctorsViewLoaded(
        doctors: results[0] as List<Doctor>,
        branches: results[1] as List<String>,
        specialties: results[2] as List<String>,
      ));
    } catch (e) {
      emit(DoctorsViewError(_errorMessage(e)));
    }
  }

  String _errorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'تعذّر الاتصال بالخادم';
    }
    return 'حدث خطأ، يرجى المحاولة مجدداً';
  }
}
