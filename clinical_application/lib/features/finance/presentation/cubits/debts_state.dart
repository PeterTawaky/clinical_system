import 'package:clinical_application/features/finance/data/models/debt_model.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';

abstract class DebtsState {}

class DebtsInitial extends DebtsState {}

class DebtsLoading extends DebtsState {}

class DebtsLoaded extends DebtsState {
  DebtsLoaded({
    required this.debts,
    required this.branches,
    required this.usernames,
  });

  final List<DebtModel> debts;
  final List<Branch> branches;
  final List<String> usernames;
}

class DebtsActionLoading extends DebtsState {
  DebtsActionLoading({
    required this.debts,
    required this.branches,
    required this.usernames,
  });

  final List<DebtModel> debts;
  final List<Branch> branches;
  final List<String> usernames;
}

class DebtsError extends DebtsState {
  DebtsError(this.message);
  final String message;
}
