import 'package:clinical_application/features/finance/data/models/treasury_model.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';

abstract class TreasuryState {}

class TreasuryInitial extends TreasuryState {}

class TreasuryLoading extends TreasuryState {}

class TreasuryLoaded extends TreasuryState {
  TreasuryLoaded({
    required this.records,
    required this.branches,
    required this.usernames,
  });

  final List<TreasuryModel> records;
  final List<Branch> branches;
  final List<String> usernames;
}

class TreasuryActionLoading extends TreasuryState {
  TreasuryActionLoading({
    required this.records,
    required this.branches,
    required this.usernames,
  });

  final List<TreasuryModel> records;
  final List<Branch> branches;
  final List<String> usernames;
}

class TreasuryError extends TreasuryState {
  TreasuryError(this.message);
  final String message;
}
