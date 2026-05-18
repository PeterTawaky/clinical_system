import 'dart:async';

import 'package:clinical_application/core/services/action_logger.dart';
import 'package:clinical_application/core/services/app_session.dart';
import 'package:clinical_application/features/finance/data/datasources/finance_datasource.dart';
import 'package:clinical_application/features/finance/data/finance_event_bus.dart';
import 'package:clinical_application/features/finance/presentation/cubits/debts_state.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DebtsCubit extends Cubit<DebtsState> {
  DebtsCubit() : super(DebtsInitial()) {
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
  bool _referenceLoaded = false;

  String? _lastCreatedDate;
  String? _lastPaymentDate;
  String? _lastUsername;
  int? _lastBranchId;

  StreamSubscription<void>? _busSubscription;
  bool _ignoreNextBusEvent = false;

  @override
  Future<void> close() {
    _busSubscription?.cancel();
    return super.close();
  }

  Future<void> _silentRefresh() async {
    if (state is DebtsInitial) return;
    await load(
      createdDate: _lastCreatedDate,
      paymentDate: _lastPaymentDate,
      username: _lastUsername,
      branchId: _lastBranchId,
    );
  }

  Future<void> load({
    String? createdDate,
    String? paymentDate,
    String? username,
    int? branchId,
  }) async {
    _lastCreatedDate = createdDate;
    _lastPaymentDate = paymentDate;
    _lastUsername = username;
    _lastBranchId = branchId;
    try {
      if (!_referenceLoaded) {
        emit(DebtsLoading());
        final results = await Future.wait([
          _ds.getBranches(),
          _ds.getUsernames(),
        ]);
        _branches = results[0] as List<Branch>;
        _usernames = results[1] as List<String>;
        _referenceLoaded = true;
      } else {
        final current = _currentLoaded();
        if (current != null) {
          emit(DebtsActionLoading(
            debts: current.debts,
            branches: _branches,
            usernames: _usernames,
          ));
        } else {
          emit(DebtsLoading());
        }
      }

      final debts = await _ds.getDebts(
        createdDate: createdDate,
        paymentDate: paymentDate,
        username: username,
        branchId: branchId,
      );
      emit(DebtsLoaded(debts: debts, branches: _branches, usernames: _usernames));
    } catch (e) {
      emit(DebtsError(e.toString()));
    }
  }

  Future<void> editDebt(
    int debtId, {
    double? amount,
    String? paymentDate,
    String? currentCreatedDate,
    String? currentPaymentDate,
    String? currentUsername,
    int? currentBranchId,
  }) async {
    try {
      _emitActionLoading();
      await _ds.updateDebt(debtId, amount: amount, paymentDate: paymentDate);
      ActionLogger.log('تعديل دين رقم: $debtId');
      await load(
        createdDate: currentCreatedDate,
        paymentDate: currentPaymentDate,
        username: currentUsername,
        branchId: currentBranchId,
      );
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(DebtsError(e.toString()));
    }
  }

  Future<void> deleteDebt(
    int debtId, {
    String? currentCreatedDate,
    String? currentPaymentDate,
    String? currentUsername,
    int? currentBranchId,
  }) async {
    try {
      _emitActionLoading();
      await _ds.deleteDebt(debtId);
      ActionLogger.log('حذف دين رقم: $debtId');
      await load(
        createdDate: currentCreatedDate,
        paymentDate: currentPaymentDate,
        username: currentUsername,
        branchId: currentBranchId,
      );
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(DebtsError(e.toString()));
    }
  }

  Future<void> payDebt(
    int debtId, {
    String? currentCreatedDate,
    String? currentPaymentDate,
    String? currentUsername,
    int? currentBranchId,
  }) async {
    try {
      _emitActionLoading();
      await _ds.payDebt(debtId, AppSession.currentUsername ?? '');
      ActionLogger.log('سداد دين رقم: $debtId');
      await load(
        createdDate: currentCreatedDate,
        paymentDate: currentPaymentDate,
        username: currentUsername,
        branchId: currentBranchId,
      );
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(DebtsError(e.toString()));
    }
  }

  void _emitActionLoading() {
    final current = _currentLoaded();
    if (current != null) {
      emit(DebtsActionLoading(
        debts: current.debts,
        branches: _branches,
        usernames: _usernames,
      ));
    }
  }

  DebtsLoaded? _currentLoaded() {
    final s = state;
    if (s is DebtsLoaded) return s;
    if (s is DebtsActionLoading) {
      return DebtsLoaded(debts: s.debts, branches: s.branches, usernames: s.usernames);
    }
    return null;
  }
}
