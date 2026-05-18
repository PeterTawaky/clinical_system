import 'package:clinical_application/features/examinations/data/models/patient_model.dart';

abstract class AddExamState {}

class AddExamInitial extends AddExamState {}

class AddExamLoadingPatients extends AddExamState {}

class AddExamReady extends AddExamState {
  AddExamReady({required this.patients});
  final List<PatientModel> patients;
}

class AddExamSubmitting extends AddExamState {}

class AddExamSuccess extends AddExamState {}

class AddExamError extends AddExamState {
  AddExamError(this.message);
  final String message;
}
