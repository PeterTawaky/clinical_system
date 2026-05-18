import 'dart:ui';

import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/core/utils/helper_functions.dart';
import 'package:clinical_application/features/examinations/presentation/views/widgets/add_exam_dialog_widget.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';
import 'package:flutter/material.dart';

class DoctorScheduleTableWidget extends StatelessWidget {
  const DoctorScheduleTableWidget({super.key, required this.doctors});

  final List<Doctor> doctors;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: doctors.length,
      itemBuilder: (context, i) => _DoctorScheduleCard(doctor: doctors[i]),
    );
  }
}

class _DoctorScheduleCard extends StatelessWidget {
  const _DoctorScheduleCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowSoft, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DoctorCardHeader(doctor: doctor),
          if (doctor.schedules.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.divider),
            _SchedulesTable(doctor: doctor),
          ] else
            const _NoSchedules(),
        ],
      ),
    );
  }
}

// ── Doctor header (info only, no book button) ───────────────────────────────

class _DoctorCardHeader extends StatelessWidget {
  const _DoctorCardHeader({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _Avatar(name: doctor.doctorName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.doctorName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Chip(
                      label: doctor.specialty,
                      color: AppColors.secondary,
                      bg: AppColors.secondaryContainer,
                    ),
                    ...doctor.branches.map((b) => _Chip(
                          label: b,
                          color: AppColors.info,
                          bg: AppColors.infoContainer,
                        )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Schedules table ──────────────────────────────────────────────────────────

class _SchedulesTable extends StatelessWidget {
  const _SchedulesTable({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const _TableHeader(),
          ...doctor.schedules.map(
            (s) => _ScheduleRow(doctor: doctor, schedule: s),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

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
          Expanded(child: _HeaderCell('اليوم')),
          Expanded(child: _HeaderCell('وقت البدء')),
          Expanded(child: _HeaderCell('وقت الانتهاء')),
          Expanded(child: _HeaderCell('الفرع')),
          Expanded(child: _HeaderCell('الحالة')),
          SizedBox(width: 80, child: _HeaderCell('حجز')),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

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

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.doctor, required this.schedule});

  final Doctor doctor;
  final DoctorSchedule schedule;

  void _openBooking(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: AddExamDialogWidget(doctor: doctor, schedule: schedule),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canBook =
        doctor.services.isNotEmpty && schedule.branchId != null && schedule.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(child: _Cell(schedule.dayOfWeek)),
          Expanded(
              child:
                  _Cell(HelperFunctions.formatTimeArabic(schedule.startTime))),
          Expanded(
              child:
                  _Cell(HelperFunctions.formatTimeArabic(schedule.endTime))),
          Expanded(child: _Cell(schedule.branchName ?? '—')),
          Expanded(
            child: Center(
              child: _StatusChip(isActive: schedule.isActive),
            ),
          ),
          SizedBox(
            width: 80,
            child: Center(
              child: _RowBookButton(
                canBook: canBook,
                onTap: () => _openBooking(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowBookButton extends StatelessWidget {
  const _RowBookButton({required this.canBook, required this.onTap});

  final bool canBook;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: canBook ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.neutral200,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 32),
        textStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('حجز'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'نشط' : 'غير نشط',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    );
  }
}

class _NoSchedules extends StatelessWidget {
  const _NoSchedules();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Center(
        child: Text(
          'لا توجد مواعيد مسجلة',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0] : 'د';
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
