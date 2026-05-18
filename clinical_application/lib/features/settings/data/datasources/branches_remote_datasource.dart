import 'package:clinical_application/core/services/networking/dio_consumer.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';

class BranchesRemoteDataSource {
  final DioConsumer _dio;

  BranchesRemoteDataSource() : _dio = DioConsumer();

  Future<List<Branch>> getBranches() async {
    final response = await _dio.get('/branches');
    final list = response as List<dynamic>;
    return list
        .map((e) => Branch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createBranch(String branchName) async {
    await _dio.post(
      '/add_branches',
      data: {'branch_name': branchName},
    );
  }

  Future<void> updateBranch(int branchId, String branchName) async {
    await _dio.put(
      '/edit_branch/$branchId',
      data: {'branch_name': branchName},
    );
  }

  Future<void> deleteBranch(int branchId) async {
    await _dio.delete('/delete_branch/$branchId');
  }
}
