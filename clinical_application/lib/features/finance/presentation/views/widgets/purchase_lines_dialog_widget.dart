import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/finance/data/models/purchase_line_model.dart';
import 'package:clinical_application/features/finance/data/models/purchase_model.dart';
import 'package:clinical_application/features/finance/presentation/cubits/purchases_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PurchaseLinesDialogWidget extends StatefulWidget {
  const PurchaseLinesDialogWidget({super.key, required this.purchase});

  final PurchaseModel purchase;

  @override
  State<PurchaseLinesDialogWidget> createState() => _PurchaseLinesDialogWidgetState();
}

class _PurchaseLinesDialogWidgetState extends State<PurchaseLinesDialogWidget> {
  List<PurchaseLineModel>? _lines;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await context.read<PurchasesCubit>().fetchLines(
          widget.purchase.purchaseId,
          (result) {
            if (mounted) {
              setState(() {
                _lines = result as List<PurchaseLineModel>;
                _loading = false;
              });
            }
          },
        );
    if (mounted && _lines == null) {
      setState(() {
        _error = 'تعذّر تحميل البنود';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(purchase: widget.purchase),
            Flexible(child: _Body(loading: _loading, error: _error, lines: _lines)),
            _Footer(total: widget.purchase.totalAmount),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.purchase});
  final PurchaseModel purchase;

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
          const Icon(Icons.list_alt_rounded, color: AppColors.onPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'بنود المشتريات #${purchase.purchaseId}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.onPrimary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.loading, required this.error, required this.lines});

  final bool loading;
  final String? error;
  final List<PurchaseLineModel>? lines;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (error != null) {
      return Center(
        child: Text(error!, style: const TextStyle(color: AppColors.error)),
      );
    }
    if (lines == null || lines!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('لا توجد بنود', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _TableHeader(),
          const Divider(height: 1, color: AppColors.divider),
          ...lines!.map((l) => _LineRow(line: l)),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HCell('اسم البند')),
          Expanded(flex: 2, child: _HCell('السعر')),
          Expanded(flex: 1, child: _HCell('الكمية')),
          Expanded(flex: 2, child: _HCell('الإجمالي')),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  const _HCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});
  final PurchaseLineModel line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _DataCell(line.name)),
          Expanded(flex: 2, child: _DataCell('${line.price.toStringAsFixed(2)} ج.م')),
          Expanded(flex: 1, child: _DataCell(line.quantity.toStringAsFixed(0))),
          Expanded(flex: 2, child: _DataCell('${line.total.toStringAsFixed(2)} ج.م', bold: true)),
        ],
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(this.text, {this.bold = false});
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'الإجمالي الكلي',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          Text(
            '${total.toStringAsFixed(2)} ج.م',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
