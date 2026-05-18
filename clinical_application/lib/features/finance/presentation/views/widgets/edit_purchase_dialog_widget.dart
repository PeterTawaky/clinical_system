import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/finance/data/models/purchase_line_model.dart';
import 'package:clinical_application/features/finance/data/models/purchase_model.dart';
import 'package:clinical_application/features/finance/presentation/cubits/purchases_cubit.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditPurchaseDialogWidget extends StatefulWidget {
  const EditPurchaseDialogWidget({
    super.key,
    required this.purchase,
    required this.branches,
    this.currentDate,
    this.currentBranchId,
    this.currentUsername,
  });

  final PurchaseModel purchase;
  final List<Branch> branches;
  final String? currentDate;
  final int? currentBranchId;
  final String? currentUsername;

  @override
  State<EditPurchaseDialogWidget> createState() => _EditPurchaseDialogWidgetState();
}

class _EditPurchaseDialogWidgetState extends State<EditPurchaseDialogWidget> {
  late final TextEditingController _descCtrl;
  late int? _selectedBranchId;
  late List<_LineEntry> _lines;
  bool _loadingLines = true;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.purchase.description ?? '');
    _selectedBranchId = widget.purchase.branchId;
    _lines = [];
    _loadLines();
  }

  Future<void> _loadLines() async {
    await context.read<PurchasesCubit>().fetchLines(
          widget.purchase.purchaseId,
          (result) {
            if (mounted) {
              setState(() {
                _lines = (result as List<PurchaseLineModel>).map((l) {
                  final e = _LineEntry();
                  e.nameCtrl.text = l.name;
                  e.priceCtrl.text = l.price.toString();
                  e.qtyCtrl.text = l.quantity.toString();
                  return e;
                }).toList();
                if (_lines.isEmpty) _lines.add(_LineEntry());
                _loadingLines = false;
              });
            }
          },
        );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final linesData = _lines
        .where((l) => l.nameCtrl.text.trim().isNotEmpty && l.priceCtrl.text.trim().isNotEmpty)
        .map((l) => {
              'name': l.nameCtrl.text.trim(),
              'price': double.tryParse(l.priceCtrl.text.trim()) ?? 0.0,
              'quantity': double.tryParse(l.qtyCtrl.text.trim()) ?? 1.0,
            })
        .toList();

    Navigator.pop(context);
    context.read<PurchasesCubit>().editPurchase(
          widget.purchase.purchaseId,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          branchId: _selectedBranchId,
          lines: linesData.isEmpty ? null : linesData,
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
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 660),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(purchaseId: widget.purchase.purchaseId),
            Flexible(
              child: _loadingLines
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.primary)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.branches.isNotEmpty) ...[
                            _DropdownField<int?>(
                              label: 'الفرع',
                              value: _selectedBranchId,
                              items: widget.branches
                                  .map((b) => DropdownMenuItem(value: b.branchId, child: Text(b.branchName)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedBranchId = v),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _TextField(controller: _descCtrl, label: 'الوصف (اختياري)', maxLines: 2),
                          const SizedBox(height: 20),
                          const _SectionTitle('بنود المشتريات'),
                          const SizedBox(height: 8),
                          ..._lines.asMap().entries.map((e) => _LineWidget(
                                entry: e.value,
                                canRemove: _lines.length > 1,
                                onRemove: () => setState(() {
                                  _lines[e.key].dispose();
                                  _lines.removeAt(e.key);
                                }),
                              )),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => setState(() => _lines.add(_LineEntry())),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('إضافة بند', style: TextStyle(fontSize: 13)),
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          ),
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

class _LineEntry {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    qtyCtrl.dispose();
  }
}

class _LineWidget extends StatelessWidget {
  const _LineWidget({required this.entry, required this.canRemove, required this.onRemove});
  final _LineEntry entry;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.neutral50, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(flex: 3, child: _TextField(controller: entry.nameCtrl, label: 'اسم البند')),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _TextField(controller: entry.priceCtrl, label: 'السعر', keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _TextField(controller: entry.qtyCtrl, label: 'الكمية', keyboardType: TextInputType.number)),
          if (canRemove) ...[
            const SizedBox(width: 6),
            IconButton(onPressed: onRemove, icon: const Icon(Icons.remove_circle_rounded, color: AppColors.error, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.purchaseId});
  final int purchaseId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded, color: AppColors.onSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('تعديل مشتريات #$purchaseId', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSecondary))),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary));
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.controller, required this.label, this.maxLines = 1, this.keyboardType});
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
        filled: true,
        fillColor: AppColors.neutral50,
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({required this.label, required this.value, required this.items, required this.onChanged});
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
        filled: true,
        fillColor: AppColors.neutral50,
      ),
    );
  }
}
