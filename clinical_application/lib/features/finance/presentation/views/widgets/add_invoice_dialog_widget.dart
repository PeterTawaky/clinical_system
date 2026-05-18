import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/finance/presentation/cubits/invoices_cubit.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddInvoiceDialogWidget extends StatefulWidget {
  const AddInvoiceDialogWidget({
    super.key,
    required this.branches,
    this.currentDate,
    this.currentBranchId,
    this.currentUsername,
  });

  final List<Branch> branches;
  final String? currentDate;
  final int? currentBranchId;
  final String? currentUsername;

  @override
  State<AddInvoiceDialogWidget> createState() => _AddInvoiceDialogWidgetState();
}

class _AddInvoiceDialogWidgetState extends State<AddInvoiceDialogWidget> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _selectedBranchId;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.branches.isNotEmpty) _selectedBranchId = widget.branches.first.branchId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    if (name.isEmpty || price == null || _selectedBranchId == null) return;

    Navigator.pop(context);
    context.read<InvoicesCubit>().addInvoice(
          name: name,
          price: price,
          branchId: _selectedBranchId!,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          createdDate: _selectedDate,
          currentDate: widget.currentDate,
          currentBranchId: widget.currentBranchId,
          currentUsername: widget.currentUsername,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _Field(controller: _nameCtrl, label: 'اسم الفاتورة'),
                    const SizedBox(height: 12),
                    _Field(controller: _priceCtrl, label: 'المبلغ', keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Dropdown<int?>(
                            label: 'الفرع',
                            value: _selectedBranchId,
                            items: widget.branches.map((b) => DropdownMenuItem(value: b.branchId, child: Text(b.branchName))).toList(),
                            onChanged: (v) => setState(() => _selectedBranchId = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _DateBtn(value: _selectedDate, onTap: _pickDate, onClear: () => setState(() => _selectedDate = null))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Field(controller: _descCtrl, label: 'الوصف (اختياري)', maxLines: 2),
                  ],
                ),
              ),
            ),
            _Actions(onCancel: () => Navigator.pop(context), onSubmit: _submit),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: AppColors.onPrimary, size: 20),
          const SizedBox(width: 10),
          const Expanded(child: Text('إضافة فاتورة جديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onPrimary))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.onPrimary, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onCancel, required this.onSubmit});
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: onCancel, child: const Text('إلغاء')),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, this.maxLines = 1, this.keyboardType});
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
        filled: true,
        fillColor: AppColors.neutral50,
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged});
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
        filled: true,
        fillColor: AppColors.neutral50,
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  const _DateBtn({required this.value, required this.onTap, required this.onClear});
  final String? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(color: AppColors.neutral50, borderRadius: BorderRadius.circular(8), border: Border.all(color: value != null ? AppColors.primary : AppColors.border)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(value != null ? _fmt(value!) : 'التاريخ (اختياري)', style: TextStyle(fontSize: 12, color: value != null ? AppColors.textPrimary : AppColors.textMuted))),
            if (value != null) GestureDetector(onTap: onClear, child: const Icon(Icons.close, size: 14, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  String _fmt(String d) {
    final p = d.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : d;
  }
}
