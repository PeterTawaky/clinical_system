import 'dart:ui';

import 'package:clinical_application/core/services/action_logger.dart';
import 'package:clinical_application/core/services/app_session.dart';
import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/examinations/data/models/examination_model.dart';
import 'package:clinical_application/features/examinations/presentation/cubits/exams_list_cubit.dart';
import 'package:clinical_application/features/examinations/presentation/cubits/exams_list_state.dart';
import 'package:clinical_application/features/examinations/presentation/views/widgets/confirm_exam_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ExamsListTabWidget extends StatefulWidget {
  const ExamsListTabWidget({
    super.key,
    required this.status,
    required this.showActions,
  });

  final String status;
  final bool showActions;

  @override
  State<ExamsListTabWidget> createState() => _ExamsListTabWidgetState();
}

class _ExamsListTabWidgetState extends State<ExamsListTabWidget>
    with AutomaticKeepAliveClientMixin {
  late final ValueNotifier<DateTime> _dateFilter;
  final ValueNotifier<String> _searchFilter = ValueNotifier('');
  late final TextEditingController _searchCtrl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _dateFilter = ValueNotifier(DateTime.now());
    _searchCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final date = _fmtDate(_dateFilter.value);
    context.read<ExamsListCubit>().load(date: date);
  }

  @override
  void dispose() {
    _dateFilter.dispose();
    _searchFilter.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    _dateFilter.value = picked;
    _load();
  }

  List<ExaminationModel> _filterBySearch(List<ExaminationModel> exams) {
    final q = _searchFilter.value.trim().toLowerCase();
    if (q.isEmpty) return exams;
    return exams
        .where((e) =>
            e.patientName.toLowerCase().contains(q) ||
            e.phone.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<ExamsListCubit, ExamsListState>(
      builder: (context, state) {
        if (state is ExamsListLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is ExamsListError) {
          return _ErrorView(
            message: state.message,
            onRetry: _load,
          );
        }

        final exams = state is ExamsListLoaded
            ? state.exams
            : state is ExamsListActionLoading
                ? state.exams
                : <ExaminationModel>[];
        final isActionLoading = state is ExamsListActionLoading;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ExamsListFilters(
                dateFilter: _dateFilter,
                searchFilter: _searchFilter,
                searchCtrl: _searchCtrl,
                onPickDate: _pickDate,
              ),
              const SizedBox(height: 10),
              _ExamsStatBar(status: widget.status, total: exams.length),
              const SizedBox(height: 10),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: _searchFilter,
                  builder: (context, _, __) {
                    final filtered = _filterBySearch(exams);
                    if (filtered.isEmpty) {
                      return const _EmptyExams();
                    }
                    return Stack(
                      children: [
                        _ExamsTable(
                          exams: filtered,
                          showActions: widget.showActions,
                          dateStr: _fmtDate(_dateFilter.value),
                        ),
                        if (isActionLoading)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Color(0x44FFFFFF),
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExamsListFilters extends StatelessWidget {
  const _ExamsListFilters({
    required this.dateFilter,
    required this.searchFilter,
    required this.searchCtrl,
    required this.onPickDate,
  });

  final ValueNotifier<DateTime> dateFilter;
  final ValueNotifier<String> searchFilter;
  final TextEditingController searchCtrl;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchCtrl,
            textDirection: TextDirection.rtl,
            onChanged: (v) => searchFilter.value = v,
            decoration: InputDecoration(
              hintText: 'بحث باسم المريض...',
              hintTextDirection: TextDirection.rtl,
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ValueListenableBuilder<DateTime>(
          valueListenable: dateFilter,
          builder: (context, date, _) {
            return OutlinedButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label: Text(_fmtDate(date)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ExamsTable extends StatelessWidget {
  const _ExamsTable({
    required this.exams,
    required this.showActions,
    required this.dateStr,
  });

  final List<ExaminationModel> exams;
  final bool showActions;
  final String dateStr;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _ExamsTableHeader(showActions: showActions),
          ...exams.map((e) => _ExamRow(
                exam: e,
                showActions: showActions,
                dateStr: dateStr,
              )),
        ],
      ),
    );
  }
}

class _ExamsTableHeader extends StatelessWidget {
  const _ExamsTableHeader({required this.showActions});

  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Expanded(flex: 2, child: _HCell('الخدمة')),
          const Expanded(child: _HCell('السعر')),
          const Expanded(flex: 2, child: _HCell('المريض')),
          const Expanded(flex: 2, child: _HCell('الطبيب')),
          const Expanded(child: _HCell('الهاتف')),
          const Expanded(child: _HCell('الحالة')),
          if (showActions) const Expanded(flex: 2, child: _HCell('الإجراءات')),
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
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}

class _ExamRow extends StatelessWidget {
  const _ExamRow({
    required this.exam,
    required this.showActions,
    required this.dateStr,
  });

  final ExaminationModel exam;
  final bool showActions;
  final String dateStr;

  Color get _statusColor {
    switch (exam.status) {
      case 'مؤكد':
        return AppColors.success;
      case 'ملغي':
        return AppColors.statusCancelled;
      default:
        return AppColors.warning;
    }
  }

  Color get _statusBg {
    switch (exam.status) {
      case 'مؤكد':
        return AppColors.successContainer;
      case 'ملغي':
        return AppColors.neutral100;
      default:
        return AppColors.warningContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _DCell(exam.serviceName)),
          Expanded(child: _DCell('${exam.price.toStringAsFixed(0)} ج.م')),
          Expanded(flex: 2, child: _DCell(exam.patientName)),
          Expanded(flex: 2, child: _DCell(exam.doctorName)),
          Expanded(child: _DCell(exam.phone)),
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exam.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ),
          ),
          if (showActions)
            Expanded(
              flex: 2,
              child: _ExamActions(
                exam: exam,
                dateStr: dateStr,
              ),
            ),
        ],
      ),
    );
  }
}

class _DCell extends StatelessWidget {
  const _DCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style:
          const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ExamActions extends StatelessWidget {
  const _ExamActions({
    required this.exam,
    required this.dateStr,
  });

  final ExaminationModel exam;
  final String dateStr;

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: Text('هل تريد إلغاء كشف #${exam.examId}؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لا')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إلغاء الكشف',
                style: TextStyle(color: AppColors.onError)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context
          .read<ExamsListCubit>()
          .cancelExam(exam.examId, date: dateStr);
      ActionLogger.log('إلغاء كشف رقم: ${exam.examId} - المريض: ${exam.patientName}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إلغاء الكشف'),
              backgroundColor: AppColors.warning),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('حدث خطأ أثناء الإلغاء'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _confirm(BuildContext context) async {
    final username = AppSession.currentUsername;
    if (username == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: ConfirmExamDialogWidget(
          examId: exam.examId,
          patientName: exam.patientName,
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context
          .read<ExamsListCubit>()
          .confirmExam(exam.examId, username, date: dateStr);
      ActionLogger.log('تأكيد كشف رقم: ${exam.examId} - المريض: ${exam.patientName}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تأكيد الكشف'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('حدث خطأ أثناء التأكيد'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: 'إلغاء',
          child: IconButton(
            onPressed: () => _cancel(context),
            icon: const Icon(Icons.cancel_rounded, size: 20),
            color: AppColors.error,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.errorContainer,
              padding: const EdgeInsets.all(6),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: 'تأكيد',
          child: IconButton(
            onPressed: () => _confirm(context),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            color: AppColors.success,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.successContainer,
              padding: const EdgeInsets.all(6),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExamsStatBar extends StatelessWidget {
  const _ExamsStatBar({required this.status, required this.total});

  final String status;
  final int total;

  Color get _color {
    switch (status) {
      case 'مؤكد':
        return AppColors.success;
      case 'ملغي':
        return AppColors.statusCancelled;
      default:
        return AppColors.warning;
    }
  }

  Color get _bgColor {
    switch (status) {
      case 'مؤكد':
        return AppColors.successContainer;
      case 'ملغي':
        return AppColors.neutral100;
      default:
        return AppColors.warningContainer;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'مؤكد':
        return Icons.check_circle_rounded;
      case 'ملغي':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_icon, size: 18, color: _color),
          const SizedBox(width: 8),
          Text(
            'إجمالي الكشوفات $status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExams extends StatelessWidget {
  const _EmptyExams();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 56, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('لا توجد كشوفات',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
