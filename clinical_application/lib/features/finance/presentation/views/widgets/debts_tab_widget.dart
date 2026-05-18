import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/finance/data/models/debt_model.dart';
import 'package:clinical_application/features/finance/presentation/cubits/debts_cubit.dart';
import 'package:clinical_application/features/finance/presentation/cubits/debts_state.dart';
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

class DebtsTabWidget extends StatefulWidget {
  const DebtsTabWidget({super.key});

  @override
  State<DebtsTabWidget> createState() => _DebtsTabWidgetState();
}

class _DebtsTabWidgetState extends State<DebtsTabWidget> {
  final _dateFilter = ValueNotifier<String?>(null);
  final _paymentDateFilter = ValueNotifier<String?>(null);
  final _branchFilter = ValueNotifier<int?>(null);
  final _usernameFilter = ValueNotifier<String?>(null);
  final _statusFilter = ValueNotifier<String?>('مديونية');

  @override
  void dispose() {
    _dateFilter.dispose();
    _paymentDateFilter.dispose();
    _branchFilter.dispose();
    _usernameFilter.dispose();
    _statusFilter.dispose();
    super.dispose();
  }

  void _reload(BuildContext context) {
    context.read<DebtsCubit>().load(
      createdDate: _dateFilter.value,
      paymentDate: _paymentDateFilter.value,
      username: _usernameFilter.value,
      branchId: _branchFilter.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebtsCubit, DebtsState>(
      builder: (context, state) {
        if (state is DebtsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is DebtsError) {
          return _ErrorRetry(
            message: state.message,
            onRetry: () => _reload(context),
          );
        }

        final isLoaded = state is DebtsLoaded || state is DebtsActionLoading;
        if (!isLoaded) return const SizedBox.shrink();

        final debts = state is DebtsLoaded
            ? state.debts
            : (state as DebtsActionLoading).debts;
        final branches = state is DebtsLoaded
            ? state.branches
            : (state as DebtsActionLoading).branches;
        final usernames = state is DebtsLoaded
            ? state.usernames
            : (state as DebtsActionLoading).usernames;
        final isActing = state is DebtsActionLoading;

        return ValueListenableBuilder<String?>(
          valueListenable: _statusFilter,
          builder: (context, statusVal, _) {
            final filtered = statusVal == null
                ? debts
                : debts.where((d) => d.status == statusVal).toList();

            final totalAmt = debts.fold(0.0, (s, d) => s + d.amount);
            final paidAmt = debts
                .where((d) => d.status == 'تم السداد')
                .fold(0.0, (s, d) => s + d.amount);
            final unpaidAmt = debts
                .where((d) => d.status == 'مديونية')
                .fold(0.0, (s, d) => s + d.amount);

            return Column(
              children: [
                FinanceFiltersRowWidget(
                  branches: branches,
                  usernames: usernames,
                  branchFilter: _branchFilter,
                  usernameFilter: _usernameFilter,
                  dateFilter: _dateFilter,
                  paymentDateFilter: _paymentDateFilter,
                  statusFilter: _statusFilter,
                  statusOptions: const ['مديونية', 'تم السداد'],
                  onFiltersChanged: () => _reload(context),
                ),
                FinanceStatsBarWidget(
                  stats: [
                    FinanceStatItem(
                      label: 'إجمالي المصروفات',
                      value: _fmtAmt(totalAmt),
                      color: AppColors.primary,
                      bg: AppColors.primaryContainer,
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                    FinanceStatItem(
                      label: 'المسددة',
                      value: _fmtAmt(paidAmt),
                      color: AppColors.success,
                      bg: AppColors.successContainer,
                      icon: Icons.check_circle_rounded,
                    ),
                    FinanceStatItem(
                      label: 'غير المسددة',
                      value: _fmtAmt(unpaidAmt),
                      color: AppColors.error,
                      bg: AppColors.errorContainer,
                      icon: Icons.warning_rounded,
                    ),
                    FinanceStatItem(
                      label: 'عدد الحركات',
                      value: '${debts.length}',
                      color: AppColors.info,
                      bg: AppColors.infoContainer,
                      icon: Icons.list_alt_rounded,
                    ),
                  ],
                ),
                Expanded(
                  child: Stack(
                    children: [
                      filtered.isEmpty
                          ? const _EmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => _DebtCard(
                                debt: filtered[i],
                                onPay: filtered[i].status == 'مديونية'
                                    ? () => _confirmPay(context, filtered[i])
                                    : null,
                              ),
                            ),
                      if (isActing)
                        const Positioned.fill(child: _LoadingOverlay()),
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

  void _confirmPay(BuildContext context, DebtModel debt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد السداد'),
        content: Text(
          'هل تريد سداد الدين رقم ${debt.debtId}؟\nالمبلغ: ${_fmtAmt(debt.amount)}\nالمصدر: ${debt.source}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.pop(context);
              context.read<DebtsCubit>().payDebt(
                debt.debtId,
                currentCreatedDate: _dateFilter.value,
                currentPaymentDate: _paymentDateFilter.value,
                currentUsername: _usernameFilter.value,
                currentBranchId: _branchFilter.value,
              );
            },
            child: const Text('سداد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt, this.onPay});

  final DebtModel debt;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final isPaid = debt.status == 'تم السداد';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _DebtIcon(isPaid: isPaid),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'دين #${debt.debtId}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: debt.status),
                          const SizedBox(width: 8),
                          _SourceBadge(source: debt.source),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _InfoChip(
                            Icons.calendar_today_rounded,
                            'إنشاء: ${_fmtDate(debt.creationDate)}',
                          ),
                          if (debt.paymentDate != null &&
                              debt.paymentDate!.isNotEmpty)
                            _InfoChip(
                              Icons.event_available_rounded,
                              'سداد: ${_fmtDate(debt.paymentDate)}',
                            ),
                          _InfoChip(Icons.business_rounded, debt.branchName),
                          _InfoChip(Icons.person_rounded, debt.username),
                          _InfoChip(Icons.category_rounded, debt.categoryName),
                        ],
                      ),
                      if (debt.description != null &&
                          debt.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _DescriptionRow(debt.description!),
                      ],
                    ],
                  ),
                ),
                Text(
                  _fmtAmt(debt.amount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isPaid ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          if (onPay != null)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: _CardAction(
                icon: Icons.payments_rounded,
                label: 'سداد',
                color: AppColors.success,
                onTap: onPay!,
              ),
            ),
        ],
      ),
    );
  }
}

class _DebtIcon extends StatelessWidget {
  const _DebtIcon({required this.isPaid});
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isPaid ? AppColors.successContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isPaid
            ? Icons.check_circle_rounded
            : Icons.account_balance_wallet_rounded,
        color: isPaid ? AppColors.success : AppColors.error,
        size: 22,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'تم السداد';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPaid ? AppColors.successContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isPaid ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.infoContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        source,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.info,
        ),
      ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
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
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 56,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12),
          Text(
            'لا توجد ديون',
            style: TextStyle(color: AppColors.textSecondary),
          ),
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
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
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
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
