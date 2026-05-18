import 'package:clinical_application/features/settings/data/models/doctor_model.dart';

sealed class DoctorsState {}

class DoctorsInitial extends DoctorsState {}

class DoctorsLoading extends DoctorsState {}

class DoctorsLoaded extends DoctorsState {
  final List<Doctor> doctors;
  final List<String> branches;
  final List<String> specialties;

  DoctorsLoaded(this.doctors, {required this.branches, required this.specialties});
}

class DoctorsActionLoading extends DoctorsState {
  final List<Doctor> doctors;
  DoctorsActionLoading(this.doctors);
}

class DoctorsError extends DoctorsState {
  final String message;
  final List<Doctor> doctors;
  DoctorsError(this.message, this.doctors);
}
