import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';

abstract class BookExamState {}

class BookExamInitial extends BookExamState {}

class BookExamLoading extends BookExamState {}

class BookExamLoaded extends BookExamState {
  BookExamLoaded({
    required this.doctors,
    required this.branches,
    required this.specialties,
  });

  final List<Doctor> doctors;
  final List<Branch> branches;
  final List<String> specialties;
}

class BookExamError extends BookExamState {
  BookExamError(this.message);
  final String message;
}
