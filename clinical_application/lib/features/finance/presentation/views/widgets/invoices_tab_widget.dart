import 'dart:ui';

import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/finance/data/models/invoice_model.dart';
import 'package:clinical_application/features/finance/presentation/cubits/invoices_cubit.dart';
import 'package:clinical_application/features/finance/presentation/cubits/invoices_state.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/add_invoice_dialog_widget.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/edit_invoice_dialog_widget.dart';
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

class InvoicesTabWidget extends StatefulWidget {
  const InvoicesTabWidget({super.key});

  @override
  State<InvoicesTabWidget> createState() => _InvoicesTabWidgetState();
}

class _InvoicesTabWidgetState extends State<InvoicesTabWidget> {
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
    context.read<InvoicesCubit>().load(
          date: _dateFilter.value,
          branchId: _branchFilter.value,
          username: _usernameFilter.value,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoicesCubit, InvoicesState>(
      builder: (context, state) {
        if (state is InvoicesLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is InvoicesError) {
          return _ErrorRetry(message: state.message, onRetry: () => _reload(context));
        }

        final isLoaded = state is InvoicesLoaded || state is InvoicesActionLoading;
        if (!isLoaded) return const SizedBox.shrink();

        final invoices = state is InvoicesLoaded ? state.invoices : (state as InvoicesActionLoading).invoices;
        final branches = state is InvoicesLoaded ? state.branches : (state as InvoicesActionLoading).branches;
        final usernames = state is InvoicesLoaded ? state.usernames : (state as InvoicesActionLoading).usernames;
        final isActing = state is InvoicesActionLoading;

        return ValueListenableBuilder<String?>(
          valueListenable: _statusFilter,
          builder: (context, statusVal, _) {
            final filtered = statusVal == null ? invoices : invoices.where((i) => i.status == statusVal).toList();

            final totalAmt = invoices.fold(0.0, (s, i) => s + i.price);
            final paidAmt = invoices.where((i) => i.status == 'تم السداد').fold(0.0, (s, i) => s + i.price);
            final unpaidAmt = invoices.where((i) => i.status == 'مديونية').fold(0.0, (s, i) => s + i.price);

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
                FinanceStatsBarWidget(stats: [
                  FinanceStatItem(label: 'إجمالي الفواتير', value: _fmtAmt(totalAmt), color: AppColors.primary, bg: AppColors.primaryContainer, icon: Icons.receipt_long_rounded),
                  FinanceStatItem(label: 'المدفوع', value: _fmtAmt(paidAmt), color: AppColors.success, bg: AppColors.successContainer, icon: Icons.check_circle_rounded),
                  FinanceStatItem(label: 'غير المدفوع', value: _fmtAmt(unpaidAmt), color: AppColors.warning, bg: AppColors.warningContainer, icon: Icons.pending_rounded),
                  FinanceStatItem(label: 'عدد الفواتير', value: '${invoices.length}', color: AppColors.info, bg: AppColors.infoContainer, icon: Icons.list_alt_rounded),
                ]),
                Expanded(
                  child: Stack(
                    children: [
                      filtered.isEmpty
                          ? const _EmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => _InvoiceCard(
                                invoice: filtered[i],
                                onEdit: () => _openEdit(context, filtered[i], branches),
                                onDelete: () => _confirmDelete(context, filtered[i]),
                                onPay: filtered[i].status == 'مديونية' ? () => _confirmPay(context, filtered[i]) : null,
                              ),
                            ),
                      if (isActing) const Positioned.fill(child: _LoadingOverlay()),
                    ],
                  ),
                ),
                _AddInvoiceButton(onTap: () => _openAdd(context, branches)),
              ],
            );
          },
        );
      },
    );
  }

  void _openAdd(BuildContext context, branches) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: BlocProvider.value(
          value: context.read<InvoicesCubit>(),
          child: AddInvoiceDialogWidget(
            branches: branches,
            currentDate: _dateFilter.value,
            currentBranchId: _branchFilter.value,
            currentUsername: _usernameFilter.value,
          ),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, InvoiceModel invoice, branches) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: BlocProvider.value(
          value: context.read<InvoicesCubit>(),
          child: EditInvoiceDialogWidget(
            invoice: invoice,
            branches: branches,
            currentDate: _dateFilter.value,
            currentBranchId: _branchFilter.value,
            currentUsername: _usernameFilter.value,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الفاتورة رقم ${invoice.invoiceId}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              context.read<InvoicesCubit>().deleteInvoice(invoice.invoiceId, currentDate: _dateFilter.value, currentBranchId: _branchFilter.value, currentUsername: _usernameFilter.value);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmPay(BuildContext context, InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد السداد'),
        content: Text('هل تريد سداد الفاتورة "${invoice.name}"؟\nالمبلغ: ${_fmtAmt(invoice.price)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.pop(context);
              context.read<InvoicesCubit>().payInvoice(invoice.invoiceId, currentDate: _dateFilter.value, currentBranchId: _branchFilter.value, currentUsername: _usernameFilter.value);
            },
            child: const Text('سداد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.onEdit, required this.onDelete, this.onPay});

  final InvoiceModel invoice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final isPaid = invoice.status == 'تم السداد';
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
                _InvoiceIcon(isPaid: isPaid),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              invoice.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ),
                          _StatusBadge(status: invoice.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (invoice.description != null && invoice.description!.isNotEmpty)
                        Text(invoice.description!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _InfoChip(Icons.calendar_today_rounded, _fmtDate(invoice.createdDate)),
                          _InfoChip(Icons.business_rounded, invoice.branchName),
                          _InfoChip(Icons.person_rounded, invoice.username),
                          _InfoChip(Icons.category_rounded, invoice.categoryName),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  _fmtAmt(invoice.price),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isPaid ? AppColors.success : AppColors.warning),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
            child: Row(
              children: [
                _CardAction(icon: Icons.edit_rounded, label: 'تعديل', color: AppColors.secondary, onTap: onEdit),
                const _VDivider(),
                if (onPay != null) ...[
                  _CardAction(icon: Icons.payments_rounded, label: 'سداد', color: AppColors.success, onTap: onPay!),
                  const _VDivider(),
                ],
                _CardAction(icon: Icons.delete_rounded, label: 'حذف', color: AppColors.error, onTap: onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceIcon extends StatelessWidget {
  const _InvoiceIcon({required this.isPaid});
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
      child: Icon(isPaid ? Icons.receipt_long_rounded : Icons.receipt_rounded, color: isPaid ? AppColors.success : AppColors.warning, size: 22),
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
      decoration: BoxDecoration(color: isPaid ? AppColors.successContainer : AppColors.warningContainer, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isPaid ? AppColors.success : AppColors.warning)),
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
  const _CardAction({required this.icon, required this.label, required this.color, required this.onTap});
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
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 30, child: VerticalDivider(color: AppColors.divider, width: 1));
  }
}

class _AddInvoiceButton extends StatelessWidget {
  const _AddInvoiceButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('إضافة فاتورة جديدة'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
          Icon(Icons.receipt_long_rounded, size: 56, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('لا توجد فواتير', style: TextStyle(color: AppColors.textSecondary)),
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
