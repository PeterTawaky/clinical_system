import 'package:clinical_application/features/settings/data/models/doctor_model.dart';

sealed class DoctorsViewState {}

class DoctorsViewInitial extends DoctorsViewState {}

class DoctorsViewLoading extends DoctorsViewState {}

class DoctorsViewLoaded extends DoctorsViewState {
  final List<Doctor> doctors;
  final List<String> branches;
  final List<String> specialties;

  DoctorsViewLoaded({
    required this.doctors,
    required this.branches,
    required this.specialties,
  });
}

class DoctorsViewError extends DoctorsViewState {
  final String message;
  DoctorsViewError(this.message);
}
