import 'dart:async';

import 'package:clinical_application/core/services/action_logger.dart';
import 'package:clinical_application/core/services/app_session.dart';
import 'package:clinical_application/features/finance/data/datasources/finance_datasource.dart';
import 'package:clinical_application/features/finance/data/finance_event_bus.dart';
import 'package:clinical_application/features/finance/data/models/expense_category_model.dart';
import 'package:clinical_application/features/finance/presentation/cubits/invoices_state.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvoicesCubit extends Cubit<InvoicesState> {
  InvoicesCubit() : super(InvoicesInitial()) {
    _busSubscription = FinanceEventBus.onDataChanged.listen((_) {
      if (_ignoreNextBusEvent) {
        _ignoreNextBusEvent = false;
        return;
      }
      _silentRefresh();
    });
  }

  final _ds = FinanceDatasource();

  List<Branch> _branches = [];
  List<String> _usernames = [];
  List<ExpenseCategory> _categories = [];
  bool _referenceLoaded = false;

  String? _lastDate;
  int? _lastBranchId;
  String? _lastUsername;

  StreamSubscription<void>? _busSubscription;
  bool _ignoreNextBusEvent = false;

  @override
  Future<void> close() {
    _busSubscription?.cancel();
    return super.close();
  }

  Future<void> _silentRefresh() async {
    if (state is InvoicesInitial) return;
    await load(date: _lastDate, branchId: _lastBranchId, username: _lastUsername);
  }

  Future<void> load({String? date, int? branchId, String? username}) async {
    _lastDate = date;
    _lastBranchId = branchId;
    _lastUsername = username;
    try {
      if (!_referenceLoaded) {
        emit(InvoicesLoading());
        final results = await Future.wait([
          _ds.getBranches(),
          _ds.getUsernames(),
          _ds.getCategories(),
        ]);
        _branches = results[0] as List<Branch>;
        _usernames = results[1] as List<String>;
        _categories = results[2] as List<ExpenseCategory>;
        _referenceLoaded = true;
      } else {
        final current = _currentLoaded();
        if (current != null) {
          emit(InvoicesActionLoading(
            invoices: current.invoices,
            branches: _branches,
            usernames: _usernames,
            categories: _categories,
          ));
        } else {
          emit(InvoicesLoading());
        }
      }

      final invoices = await _ds.getInvoices(
        branchId: branchId,
        createdDate: date,
        username: username,
      );
      emit(InvoicesLoaded(
        invoices: invoices,
        branches: _branches,
        usernames: _usernames,
        categories: _categories,
      ));
    } catch (e) {
      emit(InvoicesError(e.toString()));
    }
  }

  int? _invoicesCategoryId() {
    try {
      return _categories.firstWhere((c) => c.categoryName == 'فواتير').categoryId;
    } catch (_) {
      return _categories.isNotEmpty ? _categories.first.categoryId : null;
    }
  }

  Future<void> addInvoice({
    required String name,
    required double price,
    required int branchId,
    String? description,
    String? createdDate,
    String? currentDate,
    int? currentBranchId,
    String? currentUsername,
  }) async {
    try {
      _emitActionLoading();
      final username = AppSession.currentUsername ?? '';
      final categoryId = _invoicesCategoryId();
      if (categoryId == null) throw Exception('فئة الفواتير غير موجودة');
      await _ds.createInvoice(
        username: username,
        name: name,
        price: price,
        branchId: branchId,
        description: description,
        categoryId: categoryId,
        createdDate: createdDate,
      );
      ActionLogger.log('إضافة فاتورة جديدة: $name');
      await load(date: currentDate, branchId: currentBranchId, username: currentUsername);
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(InvoicesError(e.toString()));
    }
  }

  Future<void> editInvoice(
    int invoiceId, {
    String? name,
    double? price,
    int? branchId,
    String? description,
    String? currentDate,
    int? currentBranchId,
    String? currentUsername,
  }) async {
    try {
      _emitActionLoading();
      await _ds.updateInvoice(
        invoiceId,
        name: name,
        price: price,
        branchId: branchId,
        description: description,
      );
      ActionLogger.log('تعديل فاتورة رقم: $invoiceId');
      await load(date: currentDate, branchId: currentBranchId, username: currentUsername);
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(InvoicesError(e.toString()));
    }
  }

  Future<void> deleteInvoice(
    int invoiceId, {
    String? currentDate,
    int? currentBranchId,
    String? currentUsername,
  }) async {
    try {
      _emitActionLoading();
      await _ds.deleteInvoice(invoiceId);
      ActionLogger.log('حذف فاتورة رقم: $invoiceId');
      await load(date: currentDate, branchId: currentBranchId, username: currentUsername);
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(InvoicesError(e.toString()));
    }
  }

  Future<void> payInvoice(
    int invoiceId, {
    String? currentDate,
    int? currentBranchId,
    String? currentUsername,
  }) async {
    try {
      _emitActionLoading();
      await _ds.payInvoice(invoiceId, AppSession.currentUsername ?? '');
      ActionLogger.log('سداد فاتورة رقم: $invoiceId');
      await load(date: currentDate, branchId: currentBranchId, username: currentUsername);
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(InvoicesError(e.toString()));
    }
  }

  void _emitActionLoading() {
    final current = _currentLoaded();
    if (current != null) {
      emit(InvoicesActionLoading(
        invoices: current.invoices,
        branches: _branches,
        usernames: _usernames,
        categories: _categories,
      ));
    }
  }

  InvoicesLoaded? _currentLoaded() {
    final s = state;
    if (s is InvoicesLoaded) return s;
    if (s is InvoicesActionLoading) {
      return InvoicesLoaded(
        invoices: s.invoices,
        branches: s.branches,
        usernames: s.usernames,
        categories: s.categories,
      );
    }
    return null;
  }
}
