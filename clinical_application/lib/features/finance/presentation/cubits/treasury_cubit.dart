import 'dart:async';

import 'package:clinical_application/core/services/action_logger.dart';
import 'package:clinical_application/features/finance/data/datasources/finance_datasource.dart';
import 'package:clinical_application/features/finance/data/finance_event_bus.dart';
import 'package:clinical_application/features/finance/presentation/cubits/treasury_state.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TreasuryCubit extends Cubit<TreasuryState> {
  TreasuryCubit() : super(TreasuryInitial()) {
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
  String? _lastTransactionType;
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
    if (state is TreasuryInitial) return;
    await load(
      createdDate: _lastCreatedDate,
      transactionType: _lastTransactionType,
      username: _lastUsername,
      branchId: _lastBranchId,
    );
  }

  Future<void> load({
    String? createdDate,
    String? transactionType,
    String? username,
    int? branchId,
  }) async {
    _lastCreatedDate = createdDate;
    _lastTransactionType = transactionType;
    _lastUsername = username;
    _lastBranchId = branchId;
    try {
      if (!_referenceLoaded) {
        emit(TreasuryLoading());
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
          emit(TreasuryActionLoading(
            records: current.records,
            branches: _branches,
            usernames: _usernames,
          ));
        } else {
          emit(TreasuryLoading());
        }
      }

      final records = await _ds.getTreasury(
        createdDate: createdDate,
        transactionType: transactionType,
        username: username,
        branchId: branchId,
      );
      emit(TreasuryLoaded(records: records, branches: _branches, usernames: _usernames));
    } catch (e) {
      emit(TreasuryError(e.toString()));
    }
  }

  Future<void> editTreasury(
    int treasuryId, {
    double? amount,
    String? transactionType,
    String? currentDate,
    String? currentTransactionType,
    String? currentUsername,
    int? currentBranchId,
  }) async {
    try {
      _emitActionLoading();
      await _ds.updateTreasury(treasuryId, amount: amount, transactionType: transactionType);
      ActionLogger.log('تعديل حركة خزنة رقم: $treasuryId');
      await load(
        createdDate: currentDate,
        transactionType: currentTransactionType,
        username: currentUsername,
        branchId: currentBranchId,
      );
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(TreasuryError(e.toString()));
    }
  }

  Future<void> deleteTreasury(
    int treasuryId, {
    String? currentDate,
    String? currentTransactionType,
    String? currentUsername,
    int? currentBranchId,
  }) async {
    try {
      _emitActionLoading();
      await _ds.deleteTreasury(treasuryId);
      ActionLogger.log('حذف حركة خزنة رقم: $treasuryId');
      await load(
        createdDate: currentDate,
        transactionType: currentTransactionType,
        username: currentUsername,
        branchId: currentBranchId,
      );
      _ignoreNextBusEvent = true;
      FinanceEventBus.notify();
    } catch (e) {
      emit(TreasuryError(e.toString()));
    }
  }

  void _emitActionLoading() {
    final current = _currentLoaded();
    if (current != null) {
      emit(TreasuryActionLoading(
        records: current.records,
        branches: _branches,
        usernames: _usernames,
      ));
    }
  }

  TreasuryLoaded? _currentLoaded() {
    final s = state;
    if (s is TreasuryLoaded) return s;
    if (s is TreasuryActionLoading) {
      return TreasuryLoaded(records: s.records, branches: s.branches, usernames: s.usernames);
    }
    return null;
  }
}
