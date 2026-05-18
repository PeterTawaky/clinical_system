import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/finance/presentation/cubits/purchases_cubit.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddPurchaseDialogWidget extends StatefulWidget {
  const AddPurchaseDialogWidget({
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
  State<AddPurchaseDialogWidget> createState() => _AddPurchaseDialogWidgetState();
}

class _AddPurchaseDialogWidgetState extends State<AddPurchaseDialogWidget> {
  final _descCtrl = TextEditingController();
  int? _selectedBranchId;
  String? _selectedDate;
  final _lines = <_LineEntry>[];

  @override
  void initState() {
    super.initState();
    if (widget.branches.isNotEmpty) _selectedBranchId = widget.branches.first.branchId;
    _lines.add(_LineEntry());
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _addLine() => setState(() => _lines.add(_LineEntry()));

  void _removeLine(int i) => setState(() {
        _lines[i].dispose();
        _lines.removeAt(i);
      });

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submit() {
    if (_selectedBranchId == null) return;

    final linesData = _lines
        .where((l) => l.nameCtrl.text.trim().isNotEmpty && l.priceCtrl.text.trim().isNotEmpty)
        .map((l) => {
              'name': l.nameCtrl.text.trim(),
              'price': double.tryParse(l.priceCtrl.text.trim()) ?? 0.0,
              'quantity': double.tryParse(l.qtyCtrl.text.trim()) ?? 1.0,
            })
        .toList();

    if (linesData.isEmpty) return;

    Navigator.pop(context);
    context.read<PurchasesCubit>().addPurchase(
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          branchId: _selectedBranchId!,
          createdDate: _selectedDate,
          lines: linesData,
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
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(title: 'إضافة مشتريات جديدة'),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('بيانات المشتريات'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DropdownField<int?>(
                            label: 'الفرع',
                            value: _selectedBranchId,
                            items: widget.branches
                                .map((b) => DropdownMenuItem(value: b.branchId, child: Text(b.branchName)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedBranchId = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'تاريخ المشتريات (اختياري)',
                            value: _selectedDate,
                            onTap: _pickDate,
                            onClear: () => setState(() => _selectedDate = null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TextField(
                      controller: _descCtrl,
                      label: 'الوصف (اختياري)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle('بنود المشتريات'),
                    const SizedBox(height: 8),
                    ..._lines.asMap().entries.map((e) => _LineWidget(
                          index: e.key,
                          entry: e.value,
                          canRemove: _lines.length > 1,
                          onRemove: () => _removeLine(e.key),
                        )),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _addLine,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('إضافة بند', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            _DialogActions(onCancel: () => Navigator.pop(context), onSubmit: _submit),
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
  const _LineWidget({
    required this.index,
    required this.entry,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _LineEntry entry;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _TextField(controller: entry.nameCtrl, label: 'اسم البند')),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _TextField(controller: entry.priceCtrl, label: 'السعر', keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _TextField(controller: entry.qtyCtrl, label: 'الكمية', keyboardType: TextInputType.number)),
          if (canRemove) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_rounded, color: AppColors.error, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared local widgets ──────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart_rounded, color: AppColors.onPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onPrimary))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.onPrimary, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({required this.onCancel, required this.onSubmit});
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

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap, required this.onClear});
  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value != null ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(value != null ? _fmt(value!) : label, style: TextStyle(fontSize: 12, color: value != null ? AppColors.textPrimary : AppColors.textMuted))),
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
