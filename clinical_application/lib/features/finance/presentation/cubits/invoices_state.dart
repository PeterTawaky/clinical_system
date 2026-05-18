import 'package:clinical_application/features/finance/data/models/expense_category_model.dart';
import 'package:clinical_application/features/finance/data/models/invoice_model.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';

abstract class InvoicesState {}

class InvoicesInitial extends InvoicesState {}

class InvoicesLoading extends InvoicesState {}

class InvoicesLoaded extends InvoicesState {
  InvoicesLoaded({
    required this.invoices,
    required this.branches,
    required this.usernames,
    required this.categories,
  });

  final List<InvoiceModel> invoices;
  final List<Branch> branches;
  final List<String> usernames;
  final List<ExpenseCategory> categories;
}

class InvoicesActionLoading extends InvoicesState {
  InvoicesActionLoading({
    required this.invoices,
    required this.branches,
    required this.usernames,
    required this.categories,
  });

  final List<InvoiceModel> invoices;
  final List<Branch> branches;
  final List<String> usernames;
  final List<ExpenseCategory> categories;
}

class InvoicesError extends InvoicesState {
  InvoicesError(this.message);
  final String message;
}
