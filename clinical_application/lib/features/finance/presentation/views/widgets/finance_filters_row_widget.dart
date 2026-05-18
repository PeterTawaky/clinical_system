import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:flutter/material.dart';

/// Shared filter row used by all four finance tabs.
/// Only the relevant filters are shown based on which notifiers are non-null.
class FinanceFiltersRowWidget extends StatelessWidget {
  const FinanceFiltersRowWidget({
    super.key,
    required this.branches,
    required this.usernames,
    required this.branchFilter,
    required this.usernameFilter,
    required this.dateFilter,
    this.statusFilter,
    this.statusOptions,
    this.paymentDateFilter,
    this.transactionTypeFilter,
    this.transactionTypeOptions,
    this.onFiltersChanged,
  });

  final List<Branch> branches;
  final List<String> usernames;
  final ValueNotifier<int?> branchFilter;
  final ValueNotifier<String?> usernameFilter;
  final ValueNotifier<String?> dateFilter;
  final ValueNotifier<String?>? statusFilter;
  final List<String>? statusOptions;
  final ValueNotifier<String?>? paymentDateFilter;
  final ValueNotifier<String?>? transactionTypeFilter;
  final List<String>? transactionTypeOptions;
  final VoidCallback? onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _DatePickerField(
            label: 'تاريخ الإنشاء',
            notifier: dateFilter,
            onChanged: onFiltersChanged,
          ),
          if (paymentDateFilter != null)
            _DatePickerField(
              label: 'تاريخ السداد',
              notifier: paymentDateFilter!,
              onChanged: onFiltersChanged,
            ),
          if (branches.isNotEmpty)
            _DropdownFilter<int?>(
              label: 'الفرع',
              value: branchFilter.value,
              items: [
                const DropdownMenuItem(value: null, child: Text('كل الفروع')),
                ...branches.map((b) => DropdownMenuItem(
                      value: b.branchId,
                      child: Text(b.branchName),
                    )),
              ],
              onChanged: (v) {
                branchFilter.value = v;
                onFiltersChanged?.call();
              },
            ),
          if (usernames.isNotEmpty)
            _DropdownFilter<String?>(
              label: 'المستخدم',
              value: usernameFilter.value,
              items: [
                const DropdownMenuItem(value: null, child: Text('كل المستخدمين')),
                ...usernames.map((u) => DropdownMenuItem(value: u, child: Text(u))),
              ],
              onChanged: (v) {
                usernameFilter.value = v;
                onFiltersChanged?.call();
              },
            ),
          if (statusFilter != null && statusOptions != null)
            _DropdownFilter<String?>(
              label: 'الحالة',
              value: statusFilter!.value,
              items: [
                const DropdownMenuItem(value: null, child: Text('الكل')),
                ...statusOptions!.map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (v) {
                statusFilter!.value = v;
                // status filter is local — no server reload needed
              },
            ),
          if (transactionTypeFilter != null && transactionTypeOptions != null)
            _DropdownFilter<String?>(
              label: 'نوع الحركة',
              value: transactionTypeFilter!.value,
              items: [
                const DropdownMenuItem(value: null, child: Text('الكل')),
                ...transactionTypeOptions!
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))),
              ],
              onChanged: (v) {
                transactionTypeFilter!.value = v;
                // transaction type filter is local — no server reload needed
              },
            ),
          if (dateFilter.value != null ||
              (paymentDateFilter?.value != null) ||
              branchFilter.value != null ||
              usernameFilter.value != null)
            _ClearButton(
              onClear: () {
                dateFilter.value = null;
                if (paymentDateFilter != null) paymentDateFilter!.value = null;
                branchFilter.value = null;
                usernameFilter.value = null;
                onFiltersChanged?.call();
              },
            ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.notifier,
    this.onChanged,
  });

  final String label;
  final ValueNotifier<String?> notifier;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value != null
                  ? DateTime.tryParse(value) ?? DateTime.now()
                  : DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              locale: const Locale('ar'),
            );
            if (picked != null) {
              notifier.value =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              onChanged?.call();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: value != null ? AppColors.primaryContainer : AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value != null ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 15,
                  color: value != null ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  value != null ? _fmtDate(value) : label,
                  style: TextStyle(
                    fontSize: 13,
                    color: value != null ? AppColors.primary : AppColors.textMuted,
                    fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      notifier.value = null;
                      onChanged?.call();
                    },
                    child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtDate(String d) {
    final parts = d.split('-');
    if (parts.length != 3) return d;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          items: items,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onClear,
      icon: const Icon(Icons.filter_list_off_rounded, size: 16),
      label: const Text('مسح الفلاتر', style: TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.error,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}
