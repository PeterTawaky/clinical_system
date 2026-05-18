import 'dart:ui';

import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/finance/data/models/purchase_model.dart';
import 'package:clinical_application/features/finance/presentation/cubits/purchases_cubit.dart';
import 'package:clinical_application/features/finance/presentation/cubits/purchases_state.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/add_purchase_dialog_widget.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/edit_purchase_dialog_widget.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/finance_filters_row_widget.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/finance_stats_bar_widget.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/purchase_lines_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String _fmtDate(String? d) {
  if (d == null || d.isEmpty) return '—';
  final parts = d.split('-');
  if (parts.length != 3) return d;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String _fmtAmount(double v) => '${v.toStringAsFixed(2)} ج.م';

class PurchasesTabWidget extends StatefulWidget {
  const PurchasesTabWidget({super.key});

  @override
  State<PurchasesTabWidget> createState() => _PurchasesTabWidgetState();
}

class _PurchasesTabWidgetState extends State<PurchasesTabWidget> {
  final _dateFilter = ValueNotifier<String?>(null);
  final _branchFilter = ValueNotifier<int?>(null);
  final _usernameFilter = ValueNotifier<String?>(null);
  final _statusFilter = ValueNotifier<String?>('مديونية');

  @override
  void dispose() {
    _dateFilter.dispose();
    _branchFilter.dispose();
    _usernameFilter.dispose();
    _statusFilter.dispose();
    super.dispose();
  }

  void _reload(BuildContext context) {
    context.read<PurchasesCubit>().load(
          date: _dateFilter.value,
          branchId: _branchFilter.value,
          username: _usernameFilter.value,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchasesCubit, PurchasesState>(
      builder: (context, state) {
        if (state is PurchasesLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is PurchasesError) {
          return _ErrorRetry(
            message: state.message,
            onRetry: () => _reload(context),
          );
        }

        final isLoaded = state is PurchasesLoaded || state is PurchasesActionLoading;
        if (!isLoaded) return const SizedBox.shrink();

        final purchases = state is PurchasesLoaded
            ? state.purchases
            : (state as PurchasesActionLoading).purchases;
        final branches = state is PurchasesLoaded
            ? state.branches
            : (state as PurchasesActionLoading).branches;
        final usernames = state is PurchasesLoaded
            ? state.usernames
            : (state as PurchasesActionLoading).usernames;
        final isActing = state is PurchasesActionLoading;

        return ValueListenableBuilder<String?>(
          valueListenable: _statusFilter,
          builder: (context, statusVal, _) {
            final filtered = statusVal == null
                ? purchases
                : purchases.where((p) => p.status == statusVal).toList();

            final totalAmount = purchases.fold(0.0, (s, p) => s + p.totalAmount);
            final paidAmount = purchases
                .where((p) => p.status == 'تم السداد')
                .fold(0.0, (s, p) => s + p.totalAmount);
            final unpaidAmount = purchases
                .where((p) => p.status == 'مديونية')
                .fold(0.0, (s, p) => s + p.totalAmount);

            return Column(
              children: [
                FinanceFiltersRowWidget(
                  branches: branches,
                  usernames: usernames,
                  branchFilter: _branchFilter,
                  usernameFilter: _usernameFilter,
                  dateFilter: _dateFilter,
                  statusFilter: _statusFilter,
                  statusOptions: const ['مديونية', 'تم السداد'],
                  onFiltersChanged: () => _reload(context),
                ),
                FinanceStatsBarWidget(
                  stats: [
                    FinanceStatItem(
                      label: 'إجمالي المشتريات',
                      value: _fmtAmount(totalAmount),
                      color: AppColors.primary,
                      bg: AppColors.primaryContainer,
                      icon: Icons.shopping_cart_rounded,
                    ),
                    FinanceStatItem(
                      label: 'المدفوع',
                      value: _fmtAmount(paidAmount),
                      color: AppColors.success,
                      bg: AppColors.successContainer,
                      icon: Icons.check_circle_rounded,
                    ),
                    FinanceStatItem(
                      label: 'غير المدفوع',
                      value: _fmtAmount(unpaidAmount),
                      color: AppColors.warning,
                      bg: AppColors.warningContainer,
                      icon: Icons.pending_rounded,
                    ),
                    FinanceStatItem(
                      label: 'عدد المشتريات',
                      value: '${purchases.length}',
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
                          ? const _EmptyState(message: 'لا توجد مشتريات')
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => _PurchaseCard(
                                purchase: filtered[i],
                                onEdit: () => _openEditDialog(context, filtered[i], branches),
                                onDelete: () => _confirmDelete(context, filtered[i]),
                                onPay: filtered[i].status == 'مديونية'
                                    ? () => _confirmPay(context, filtered[i])
                                    : null,
                                onViewLines: () => _openLines(context, filtered[i]),
                              ),
                            ),
                      if (isActing)
                        const Positioned.fill(
                          child: _LoadingOverlay(),
                        ),
                    ],
                  ),
                ),
                _AddPurchaseButton(
                  onTap: () => _openAddDialog(context, branches),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAddDialog(BuildContext context, branches) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: BlocProvider.value(
          value: context.read<PurchasesCubit>(),
          child: AddPurchaseDialogWidget(
            branches: branches,
            currentDate: _dateFilter.value,
            currentBranchId: _branchFilter.value,
            currentUsername: _usernameFilter.value,
          ),
        ),
      ),
    );
  }

  void _openEditDialog(BuildContext context, PurchaseModel purchase, branches) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: BlocProvider.value(
          value: context.read<PurchasesCubit>(),
          child: EditPurchaseDialogWidget(
            purchase: purchase,
            branches: branches,
            currentDate: _dateFilter.value,
            currentBranchId: _branchFilter.value,
            currentUsername: _usernameFilter.value,
          ),
        ),
      ),
    );
  }

  void _openLines(BuildContext context, PurchaseModel purchase) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: BlocProvider.value(
          value: context.read<PurchasesCubit>(),
          child: PurchaseLinesDialogWidget(purchase: purchase),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PurchaseModel purchase) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المشتريات رقم ${purchase.purchaseId}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              context.read<PurchasesCubit>().deletePurchase(
                    purchase.purchaseId,
                    currentDate: _dateFilter.value,
                    currentBranchId: _branchFilter.value,
                    currentUsername: _usernameFilter.value,
                  );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmPay(BuildContext context, PurchaseModel purchase) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد السداد'),
        content: Text(
          'هل تريد سداد المشتريات رقم ${purchase.purchaseId}؟\nالمبلغ: ${_fmtAmount(purchase.totalAmount)}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.pop(context);
              context.read<PurchasesCubit>().payPurchase(
                    purchase.purchaseId,
                    currentDate: _dateFilter.value,
                    currentBranchId: _branchFilter.value,
                    currentUsername: _usernameFilter.value,
                  );
            },
            child: const Text('سداد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Purchase Card ────────────────────────────────────────────────────────────

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.purchase,
    required this.onEdit,
    required this.onDelete,
    this.onPay,
    required this.onViewLines,
  });

  final PurchaseModel purchase;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPay;
  final VoidCallback onViewLines;

  @override
  Widget build(BuildContext context) {
    final isPaid = purchase.status == 'تم السداد';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowSoft, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _StatusIcon(isPaid: isPaid),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'مشتريات #${purchase.purchaseId}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: purchase.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (purchase.description != null && purchase.description!.isNotEmpty)
                        Text(
                          purchase.description!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _InfoChip(Icons.calendar_today_rounded, _fmtDate(purchase.createdDate)),
                          _InfoChip(Icons.business_rounded, purchase.branchName),
                          _InfoChip(Icons.person_rounded, purchase.username),
                          _InfoChip(Icons.category_rounded, purchase.categoryName),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  _fmtAmount(purchase.totalAmount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isPaid ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                _CardAction(
                  icon: Icons.list_alt_rounded,
                  label: 'البنود',
                  color: AppColors.primary,
                  onTap: onViewLines,
                ),
                const _Divider(),
                _CardAction(
                  icon: Icons.edit_rounded,
                  label: 'تعديل',
                  color: AppColors.secondary,
                  onTap: onEdit,
                ),
                const _Divider(),
                if (onPay != null) ...[
                  _CardAction(
                    icon: Icons.payments_rounded,
                    label: 'سداد',
                    color: AppColors.success,
                    onTap: onPay!,
                  ),
                  const _Divider(),
                ],
                _CardAction(
                  icon: Icons.delete_rounded,
                  label: 'حذف',
                  color: AppColors.error,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.isPaid});
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isPaid ? AppColors.successContainer : AppColors.warningContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
        color: isPaid ? AppColors.success : AppColors.warning,
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
        color: isPaid ? AppColors.successContainer : AppColors.warningContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isPaid ? AppColors.success : AppColors.warning,
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
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 30,
      child: VerticalDivider(color: AppColors.divider, width: 1),
    );
  }
}

class _AddPurchaseButton extends StatelessWidget {
  const _AddPurchaseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('إضافة مشتريات جديدة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
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
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
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
