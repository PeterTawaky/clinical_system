import 'package:clinical_application/features/finance/data/models/expense_category_model.dart';
import 'package:clinical_application/features/finance/data/models/purchase_model.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';

abstract class PurchasesState {}

class PurchasesInitial extends PurchasesState {}

class PurchasesLoading extends PurchasesState {}

class PurchasesLoaded extends PurchasesState {
  PurchasesLoaded({
    required this.purchases,
    required this.branches,
    required this.usernames,
    required this.categories,
  });

  final List<PurchaseModel> purchases;
  final List<Branch> branches;
  final List<String> usernames;
  final List<ExpenseCategory> categories;
}

class PurchasesActionLoading extends PurchasesState {
  PurchasesActionLoading({
    required this.purchases,
    required this.branches,
    required this.usernames,
    required this.categories,
  });

  final List<PurchaseModel> purchases;
  final List<Branch> branches;
  final List<String> usernames;
  final List<ExpenseCategory> categories;
}

class PurchasesError extends PurchasesState {
  PurchasesError(this.message);
  final String message;
}
