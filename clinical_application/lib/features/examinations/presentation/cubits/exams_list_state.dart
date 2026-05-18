import 'package:clinical_application/features/examinations/data/models/examination_model.dart';

abstract class ExamsListState {}

class ExamsListInitial extends ExamsListState {}

class ExamsListLoading extends ExamsListState {}

class ExamsListLoaded extends ExamsListState {
  ExamsListLoaded({required this.exams});
  final List<ExaminationModel> exams;
}

class ExamsListError extends ExamsListState {
  ExamsListError(this.message);
  final String message;
}

class ExamsListActionLoading extends ExamsListState {
  ExamsListActionLoading({required this.exams});
  final List<ExaminationModel> exams;
}
