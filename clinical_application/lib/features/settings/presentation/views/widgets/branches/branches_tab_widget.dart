import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/settings/presentation/cubits/branches_cubit.dart';
import 'package:clinical_application/features/settings/presentation/cubits/branches_state.dart';
import 'package:clinical_application/features/settings/presentation/views/widgets/branches/add_branch_dialog_widget.dart';
import 'package:clinical_application/features/settings/presentation/views/widgets/branches/branch_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BranchesTabWidget extends StatelessWidget {
  const BranchesTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BranchesCubit, BranchesState>(
      listener: (context, state) {
        if (state is BranchesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.onError, size: 18),
                  const SizedBox(width: 8),
                  Text(state.message),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              onAdd: () => _showAddDialog(context),
            ),
            const SizedBox(height: 20),
            BlocBuilder<BranchesCubit, BranchesState>(
              builder: (context, state) {
                return switch (state) {
                  BranchesLoading() => const _LoadingIndicator(),
                  BranchesLoaded s => _BranchesList(branches: s.branches),
                  BranchesActionLoading s => Column(
                      children: [
                        const LinearProgressIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.primaryContainer,
                        ),
                        const SizedBox(height: 8),
                        _BranchesList(branches: s.branches),
                      ],
                    ),
                  BranchesError s => _BranchesList(branches: s.branches),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) => BlocProvider.value(
        value: context.read<BranchesCubit>(),
        child: const AddBranchDialogWidget(),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_city_rounded,
              color: AppColors.onPrimary, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الفروع',
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'إضافة وتعديل وحذف فروع العيادة',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('إضافة فرع'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onPrimary,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _BranchesList extends StatelessWidget {
  const _BranchesList({required this.branches});

  final List branches;

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.location_off_rounded,
                size: 48, color: AppColors.neutral300),
            SizedBox(height: 12),
            Text('لا توجد فروع بعد',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: branches.length,
      itemBuilder: (context, index) =>
          BranchCardWidget(branch: branches[index]),
    );
  }
}
