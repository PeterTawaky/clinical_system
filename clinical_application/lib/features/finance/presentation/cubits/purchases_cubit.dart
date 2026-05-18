import 'dart:async';

import 'package:clinical_application/core/services/action_logger.dart';
import 'package:clinical_application/core/services/app_session.dart';
import 'package:clinical_application/features/finance/data/datasources/finance_datasource.dart';
import 'package:clinical_application/features/finance/data/models/expense_category_model.dart';
import 'package:clinical_application/features/finance/data/finance_event_bus.dart';
import 'package:clinical_application/features/finance/presentation/cubits/purchases_state.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PurchasesCubit extends Cubit<PurchasesState> {
  PurchasesCubit() : super(PurchasesInitial()) {
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
    if (state is PurchasesInitial) return;
    await load(date: _lastDate, branchId: _lastBranchId, username: _lastUsername);
  }

  Future<void> load({String? date, int? branchId, String? username}) async {
    _lastDate = date;
    _lastBranchId = branchId;
    _lastUsername = username;
    try {
      if (!_referenceLoaded) {
        emit(PurchasesLoading());
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
          emit(PurchasesActionLoading(
            purchases: current.purchases,
            branches: _branches,
            usernames: _usernames,
            categories: _categories,
          ));
        } else {
          emit(PurchasesLoading());
        }
      }

      final purchases = await _ds.getPurchases(
        createdDate: date,
        branchId: branchId,
        username: username,
      );
      emit(PurchasesLoaded(
        purchases: purchases,
        branches: _branches,
        usernames: _usernames,
        categories: _categories,
      ));
    } catch (e) {
      emit(PurchasesError(e.toString()));
    }
  }

  int? _purchasesCategoryId() {
    try {
      return _categories.firstWhere((c) => c.categoryName == 'مشتريات').categoryId;
    } catch (_) {
      return _categories.isNotEmpty ? _categories.first.categoryId : null;
    }
  }

  Future<void> addPurchase({
    String? description,
    required int branchId,
    String? createdDate,
    required List<Map<String, dynamic>> lines,
    String? currentDate,
    int? currentBranchId,
    String? currentUsername,
  }) async {
    try {
      _emitActionLoading();
      final username = AppSession.currentUsername ?? '';
      final categoryId = _purchasesCategoryId();
      if (categoryId == null) throw Exception('فئة المشتريات غير موجودة');
      await _ds.createPurchase(
        username: username,
        description: description,
        categoryId: categoryId,
        branchId: branchId,
        createdDate: createdDate,
        lines: lines,
      );
      ActionLogger.log('إضافة مشتريات جديدة: ${description ?? ''}');
      await load(date: currentDate, branchId: currentBranchId, username: currentUsername);
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(PurchasesError(e.toString()));
    }
  }

  Future<void> editPurchase(
    int purchaseId, {
    String? description,
    int? branchId,
    List<Map<String, dynamic>>? lines,
    String? currentDate,
    int? currentBranchId,
    String? currentUsername,
  }) async {
    try {
      _emitActionLoading();
      await _ds.updatePurchase(
        purchaseId,
        description: description,
        branchId: branchId,
        lines: lines,
      );
      ActionLogger.log('تعديل مشتريات رقم: $purchaseId');
      await load(date: currentDate, branchId: currentBranchId, username: currentUsername);
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(PurchasesError(e.toString()));
    }
  }

  Future<void> deletePurchase(
    int purchaseId, {
    String? currentDate,
    int? currentBranchId,
    String? currentUsername,
  }) async {
    try {
      _emitActionLoading();
      await _ds.deletePurchase(purchaseId);
      ActionLogger.log('حذف مشتريات رقم: $purchaseId');
      await load(date: currentDate, branchId: currentBranchId, username: currentUsername);
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(PurchasesError(e.toString()));
    }
  }

  Future<void> payPurchase(
    int purchaseId, {
    String? currentDate,
    int? currentBranchId,
    String? currentUsername,
  }) async {
    try {
      _emitActionLoading();
      await _ds.payPurchase(purchaseId, AppSession.currentUsername ?? '');
      ActionLogger.log('سداد مشتريات رقم: $purchaseId');
      await load(date: currentDate, branchId: currentBranchId, username: currentUsername);
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(PurchasesError(e.toString()));
    }
  }

  Future<void> fetchLines(int purchaseId, void Function(List) onResult) async {
    try {
      final lines = await _ds.getPurchaseLines(purchaseId);
      onResult(lines);
    } catch (_) {}
  }

  void _emitActionLoading() {
    final current = _currentLoaded();
    if (current != null) {
      emit(PurchasesActionLoading(
        purchases: current.purchases,
        branches: _branches,
        usernames: _usernames,
        categories: _categories,
      ));
    }
  }

  PurchasesLoaded? _currentLoaded() {
    final s = state;
    if (s is PurchasesLoaded) return s;
    if (s is PurchasesActionLoading) {
      return PurchasesLoaded(
        purchases: s.purchases,
        branches: s.branches,
        usernames: s.usernames,
        categories: s.categories,
      );
    }
    return null;
  }
}
