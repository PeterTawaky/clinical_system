import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/finance/data/models/invoice_model.dart';
import 'package:clinical_application/features/finance/presentation/cubits/invoices_cubit.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditInvoiceDialogWidget extends StatefulWidget {
  const EditInvoiceDialogWidget({
    super.key,
    required this.invoice,
    required this.branches,
    this.currentDate,
    this.currentBranchId,
    this.currentUsername,
  });

  final InvoiceModel invoice;
  final List<Branch> branches;
  final String? currentDate;
  final int? currentBranchId;
  final String? currentUsername;

  @override
  State<EditInvoiceDialogWidget> createState() => _EditInvoiceDialogWidgetState();
}

class _EditInvoiceDialogWidgetState extends State<EditInvoiceDialogWidget> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late int? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.invoice.name);
    _priceCtrl = TextEditingController(text: widget.invoice.price.toString());
    _descCtrl = TextEditingController(text: widget.invoice.description ?? '');
    _selectedBranchId = widget.invoice.branchId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_priceCtrl.text.trim());
    Navigator.pop(context);
    context.read<InvoicesCubit>().editInvoice(
          widget.invoice.invoiceId,
          name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          price: price,
          branchId: _selectedBranchId,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
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
            _Header(invoiceId: widget.invoice.invoiceId),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _Field(controller: _nameCtrl, label: 'اسم الفاتورة'),
                    const SizedBox(height: 12),
                    _Field(controller: _priceCtrl, label: 'المبلغ', keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _Dropdown<int?>(
                      label: 'الفرع',
                      value: _selectedBranchId,
                      items: widget.branches.map((b) => DropdownMenuItem(value: b.branchId, child: Text(b.branchName))).toList(),
                      onChanged: (v) => setState(() => _selectedBranchId = v),
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
  const _Header({required this.invoiceId});
  final int invoiceId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded, color: AppColors.onSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('تعديل فاتورة #$invoiceId', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSecondary))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.onSecondary, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.onSecondary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('حفظ التعديلات'),
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
