import 'package:clinical_application/features/settings/data/datasources/branches_remote_datasource.dart';
import 'package:clinical_application/features/settings/data/datasources/doctors_remote_datasource.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';
import 'package:clinical_application/features/settings/presentation/cubits/doctors_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoctorsCubit extends Cubit<DoctorsState> {
  DoctorsCubit() : super(DoctorsInitial()) {
    loadDoctors();
  }

  final _datasource = DoctorsRemoteDataSource();
  final _branchesDatasource = BranchesRemoteDataSource();

  List<Doctor> get _currentDoctors => switch (state) {
        DoctorsLoaded s => s.doctors,
        DoctorsActionLoading s => s.doctors,
        DoctorsError s => s.doctors,
        _ => [],
      };

  List<String> get _currentBranches =>
      state is DoctorsLoaded ? (state as DoctorsLoaded).branches : [];

  List<String> get _currentSpecialties =>
      state is DoctorsLoaded ? (state as DoctorsLoaded).specialties : [];

  Future<void> loadDoctors() async {
    emit(DoctorsLoading());
    try {
      final results = await Future.wait([
        _datasource.getDoctors(),
        _branchesDatasource.getBranches(),
        _datasource.getSpecialties(),
      ]);
      emit(DoctorsLoaded(
        results[0] as List<Doctor>,
        branches: (results[1] as List)
            .map((b) => b.branchName as String)
            .toList(),
        specialties: results[2] as List<String>,
      ));
    } catch (e) {
      emit(DoctorsError(_errorMessage(e), []));
    }
  }

  Future<void> addDoctor({
    required String doctorName,
    required String specialty,
    required String phoneNumber,
    required double balance,
    required List<int> branchIds,
    required List<DoctorSchedule> schedules,
    required List<DoctorService> services,
  }) async {
    final current = _currentDoctors;
    final branches = _currentBranches;
    final specialties = _currentSpecialties;
    emit(DoctorsActionLoading(current));
    try {
      await _datasource.createDoctor(
        doctorName: doctorName,
        specialty: specialty,
        phoneNumber: phoneNumber,
        balance: balance,
        branchIds: branchIds,
        schedules: schedules.map((s) => s.toJson()).toList(),
        services: services.map((s) => s.toJson()).toList(),
      );
      await _refresh();
    } catch (e) {
      emit(DoctorsError(_errorMessage(e), current));
      emit(DoctorsLoaded(current, branches: branches, specialties: specialties));
    }
  }

  Future<void> editDoctor({
    required int doctorId,
    String? doctorName,
    String? specialty,
    String? phoneNumber,
    double? balance,
    List<int>? branchIds,
    List<DoctorSchedule>? schedules,
    List<DoctorService>? services,
  }) async {
    final current = _currentDoctors;
    final branches = _currentBranches;
    final specialties = _currentSpecialties;
    emit(DoctorsActionLoading(current));
    try {
      await _datasource.updateDoctor(
        doctorId: doctorId,
        doctorName: doctorName,
        specialty: specialty,
        phoneNumber: phoneNumber,
        balance: balance,
        branchIds: branchIds,
        schedules: schedules?.map((s) => s.toJson()).toList(),
        services: services?.map((s) => s.toJson()).toList(),
      );
      await _refresh();
    } catch (e) {
      emit(DoctorsError(_errorMessage(e), current));
      emit(DoctorsLoaded(current, branches: branches, specialties: specialties));
    }
  }

  Future<void> deleteDoctor(int doctorId) async {
    final current = _currentDoctors;
    final branches = _currentBranches;
    final specialties = _currentSpecialties;
    emit(DoctorsActionLoading(current));
    try {
      await _datasource.deleteDoctor(doctorId);
      await _refresh();
    } catch (e) {
      emit(DoctorsError(_errorMessage(e), current));
      emit(DoctorsLoaded(current, branches: branches, specialties: specialties));
    }
  }

  Future<void> _refresh() async {
    final results = await Future.wait([
      _datasource.getDoctors(),
      _branchesDatasource.getBranches(),
      _datasource.getSpecialties(),
    ]);
    emit(DoctorsLoaded(
      results[0] as List<Doctor>,
      branches: (results[1] as List)
          .map((b) => b.branchName as String)
          .toList(),
      specialties: results[2] as List<String>,
    ));
  }

  String _errorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('404')) return 'الطبيب غير موجود';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'تعذّر الاتصال بالخادم';
    }
    return 'حدث خطأ، يرجى المحاولة مجدداً';
  }
}
