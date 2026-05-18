import 'package:clinical_application/features/settings/data/datasources/branches_remote_datasource.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:clinical_application/features/settings/presentation/cubits/branches_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BranchesCubit extends Cubit<BranchesState> {
  BranchesCubit() : super(BranchesInitial()) {
    loadBranches();
  }

  final _datasource = BranchesRemoteDataSource();

  List<Branch> get currentBranches => switch (state) {
        BranchesLoaded s => s.branches,
        BranchesActionLoading s => s.branches,
        BranchesError s => s.branches,
        _ => [],
      };

  Future<void> loadBranches() async {
    emit(BranchesLoading());
    try {
      final branches = await _datasource.getBranches();
      emit(BranchesLoaded(branches));
    } catch (e) {
      emit(BranchesError(_errorMessage(e), []));
    }
  }

  Future<void> addBranch(String branchName) async {
    final current = currentBranches;
    emit(BranchesActionLoading(current));
    try {
      await _datasource.createBranch(branchName);
      await _refresh();
    } catch (e) {
      emit(BranchesError(_errorMessage(e), current));
      emit(BranchesLoaded(current));
    }
  }

  Future<void> editBranch(int branchId, String branchName) async {
    final current = currentBranches;
    emit(BranchesActionLoading(current));
    try {
      await _datasource.updateBranch(branchId, branchName);
      await _refresh();
    } catch (e) {
      emit(BranchesError(_errorMessage(e), current));
      emit(BranchesLoaded(current));
    }
  }

  Future<void> deleteBranch(int branchId) async {
    final current = currentBranches;
    emit(BranchesActionLoading(current));
    try {
      await _datasource.deleteBranch(branchId);
      await _refresh();
    } catch (e) {
      emit(BranchesError(_errorMessage(e), current));
      emit(BranchesLoaded(current));
    }
  }

  Future<void> _refresh() async {
    final branches = await _datasource.getBranches();
    emit(BranchesLoaded(branches));
  }

  String _errorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('404')) return 'الفرع غير موجود';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'تعذّر الاتصال بالخادم';
    }
    return 'حدث خطأ، يرجى المحاولة مجدداً';
  }
}
