import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/finance/data/models/treasury_model.dart';
import 'package:clinical_application/features/finance/presentation/cubits/treasury_cubit.dart';
import 'package:clinical_application/features/finance/presentation/cubits/treasury_state.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/finance_filters_row_widget.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/finance_stats_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String _fmtDate(String? d) {
  if (d == null || d.isEmpty) return '—';
  final parts = d.split('-');
  if (parts.length != 3) return d;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String _fmtAmt(double v) => '${v.toStringAsFixed(2)} ج.م';

class TreasuryTabWidget extends StatefulWidget {
  const TreasuryTabWidget({super.key});

  @override
  State<TreasuryTabWidget> createState() => _TreasuryTabWidgetState();
}

class _TreasuryTabWidgetState extends State<TreasuryTabWidget> {
  final _dateFilter = ValueNotifier<String?>(null);
  final _branchFilter = ValueNotifier<int?>(null);
  final _usernameFilter = ValueNotifier<String?>(null);
  final _typeFilter = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _dateFilter.dispose();
    _branchFilter.dispose();
    _usernameFilter.dispose();
    _typeFilter.dispose();
    super.dispose();
  }

  void _reload(BuildContext context) {
    context.read<TreasuryCubit>().load(
          createdDate: _dateFilter.value,
          username: _usernameFilter.value,
          branchId: _branchFilter.value,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TreasuryCubit, TreasuryState>(
      builder: (context, state) {
        if (state is TreasuryLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is TreasuryError) {
          return _ErrorRetry(message: state.message, onRetry: () => _reload(context));
        }

        final isLoaded = state is TreasuryLoaded || state is TreasuryActionLoading;
        if (!isLoaded) return const SizedBox.shrink();

        final records = state is TreasuryLoaded ? state.records : (state as TreasuryActionLoading).records;
        final branches = state is TreasuryLoaded ? state.branches : (state as TreasuryActionLoading).branches;
        final usernames = state is TreasuryLoaded ? state.usernames : (state as TreasuryActionLoading).usernames;
        final isActing = state is TreasuryActionLoading;

        return ValueListenableBuilder<String?>(
          valueListenable: _typeFilter,
          builder: (context, typeVal, _) {
            final filtered = typeVal == null ? records : records.where((r) => r.transactionType == typeVal).toList();

            final totalIncome = records.where((r) => r.transactionType == 'دخل').fold(0.0, (s, r) => s + r.amount);
            final totalExpense = records.where((r) => r.transactionType == 'خرج').fold(0.0, (s, r) => s + r.amount);
            final balance = totalIncome - totalExpense;

            return Column(
              children: [
                FinanceFiltersRowWidget(
                  branches: branches,
                  usernames: usernames,
                  branchFilter: _branchFilter,
                  usernameFilter: _usernameFilter,
                  dateFilter: _dateFilter,
                  transactionTypeFilter: _typeFilter,
                  transactionTypeOptions: const ['دخل', 'خرج'],
                  onFiltersChanged: () => _reload(context),
                ),
                FinanceStatsBarWidget(stats: [
                  FinanceStatItem(label: 'إجمالي الدخل', value: _fmtAmt(totalIncome), color: AppColors.success, bg: AppColors.successContainer, icon: Icons.trending_up_rounded),
                  FinanceStatItem(label: 'إجمالي الخرج', value: _fmtAmt(totalExpense), color: AppColors.error, bg: AppColors.errorContainer, icon: Icons.trending_down_rounded),
                  FinanceStatItem(
                    label: 'الرصيد',
                    value: _fmtAmt(balance),
                    color: balance >= 0 ? AppColors.success : AppColors.error,
                    bg: balance >= 0 ? AppColors.successContainer : AppColors.errorContainer,
                    icon: Icons.account_balance_rounded,
                  ),
                  FinanceStatItem(label: 'عدد الحركات', value: '${records.length}', color: AppColors.info, bg: AppColors.infoContainer, icon: Icons.list_alt_rounded),
                ]),
                Expanded(
                  child: Stack(
                    children: [
                      filtered.isEmpty
                          ? const _EmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => _TreasuryCard(record: filtered[i]),
                            ),
                      if (isActing) const Positioned.fill(child: _LoadingOverlay()),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

class _TreasuryCard extends StatelessWidget {
  const _TreasuryCard({required this.record});

  final TreasuryModel record;

  @override
  Widget build(BuildContext context) {
    final isIncome = record.transactionType == 'دخل';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.shadowSoft, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _TreasuryIcon(isIncome: isIncome),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('خزنة #${record.treasuryId}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(width: 8),
                          _TypeBadge(type: record.transactionType),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _InfoChip(Icons.calendar_today_rounded, _fmtDate(record.creationDate)),
                          _InfoChip(Icons.business_rounded, record.branchName),
                          _InfoChip(Icons.person_rounded, record.username),
                          _InfoChip(Icons.category_rounded, record.categoryName),
                        ],
                      ),
                      if (record.description != null && record.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _DescriptionRow(record.description!),
                      ],
                    ],
                  ),
                ),
                Text(
                  _fmtAmt(record.amount),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isIncome ? AppColors.success : AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreasuryIcon extends StatelessWidget {
  const _TreasuryIcon({required this.isIncome});
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: isIncome ? AppColors.successContainer : AppColors.errorContainer, borderRadius: BorderRadius.circular(10)),
      child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIncome ? AppColors.success : AppColors.error, size: 22),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isIncome = type == 'دخل';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: isIncome ? AppColors.successContainer : AppColors.errorContainer, borderRadius: BorderRadius.circular(6)),
      child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isIncome ? AppColors.success : AppColors.error)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

class _DescriptionRow extends StatelessWidget {
  const _DescriptionRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.notes_rounded, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_rounded, size: 56, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('لا توجد حركات خزنة', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.5),
      child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary)),
        ],
      ),
    );
  }
}
