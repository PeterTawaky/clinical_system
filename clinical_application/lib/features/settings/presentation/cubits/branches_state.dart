import 'package:clinical_application/features/settings/data/models/branch_model.dart';

sealed class BranchesState {}

class BranchesInitial extends BranchesState {}

class BranchesLoading extends BranchesState {}

class BranchesLoaded extends BranchesState {
  final List<Branch> branches;
  BranchesLoaded(this.branches);
}

class BranchesActionLoading extends BranchesState {
  final List<Branch> branches;
  BranchesActionLoading(this.branches);
}

class BranchesError extends BranchesState {
  final String message;
  final List<Branch> branches;
  BranchesError(this.message, this.branches);
}
