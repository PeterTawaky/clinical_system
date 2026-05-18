import 'package:clinical_application/core/services/action_logger.dart';
import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';
import 'package:clinical_application/features/settings/presentation/cubits/doctors_cubit.dart';
import 'package:clinical_application/features/settings/presentation/views/widgets/doctors/edit_doctor_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoctorCardWidget extends StatelessWidget {
  const DoctorCardWidget({super.key, required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded,
                color: AppColors.primary, size: 22),
          ),
          title: Text(
            doctor.doctorName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.medical_information_rounded,
                    label: doctor.specialty,
                    color: AppColors.secondary,
                    bgColor: AppColors.secondaryContainer,
                  ),
                  const SizedBox(width: 6),
                  _InfoChip(
                    icon: Icons.phone_rounded,
                    label: doctor.doctorPhoneNumber,
                    color: AppColors.accent,
                    bgColor: AppColors.accentContainer,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.account_balance_wallet_rounded,
                    label: '${doctor.doctorBalance.toStringAsFixed(0)} ج.م',
                    color: AppColors.success,
                    bgColor: AppColors.successContainer,
                  ),
                  const SizedBox(width: 6),
                  if (doctor.branches.isNotEmpty)
                    Flexible(
                      child: _InfoChip(
                        icon: Icons.location_city_rounded,
                        label: doctor.branches.join(' , '),
                        color: AppColors.info,
                        bgColor: AppColors.infoContainer,
                      ),
                    ),
                ],
              ),
            ],
          ),
          trailing: _CardActions(doctor: doctor),
          children: [
            if (doctor.schedules.isNotEmpty) ...[
              const Divider(color: AppColors.divider),
              _SchedulesSection(schedules: doctor.schedules),
            ],
            if (doctor.services.isNotEmpty) ...[
              const Divider(color: AppColors.divider),
              _ServicesSection(services: doctor.services),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _openEdit(context),
          icon: const Icon(Icons.edit_rounded, size: 20),
          color: AppColors.secondary,
          tooltip: 'تعديل',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.secondaryContainer,
            minimumSize: const Size(34, 34),
            padding: const EdgeInsets.all(6),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: () => _confirmDelete(context),
          icon: const Icon(Icons.delete_rounded, size: 20),
          color: AppColors.error,
          tooltip: 'حذف',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.errorContainer,
            minimumSize: const Size(34, 34),
            padding: const EdgeInsets.all(6),
          ),
        ),
      ],
    );
  }

  void _openEdit(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) => BlocProvider.value(
        value: context.read<DoctorsCubit>(),
        child: EditDoctorDialogWidget(doctor: doctor),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<DoctorsCubit>(),
        child: _DeleteConfirmDialog(doctor: doctor),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Text(
              'حذف الطبيب',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'هل أنت متأكد من حذف الطبيب '),
              TextSpan(
                text: doctor.doctorName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const TextSpan(
                  text:
                      '؟\nسيتم حذف جميع الجداول والخدمات والكشوفات المرتبطة.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DoctorsCubit>().deleteDoctor(doctor.doctorId);
              ActionLogger.log('حذف طبيب: ${doctor.doctorName}');
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _SchedulesSection extends StatelessWidget {
  const _SchedulesSection({required this.schedules});

  final List<DoctorSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.schedule_rounded, size: 16, color: AppColors.accent),
            SizedBox(width: 6),
            Text(
              'مواعيد العمل',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: schedules.map((s) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.dayOfWeek,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatTime(s.startTime)} - ${_formatTime(s.endTime)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (s.branchName != null) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.location_on_rounded,
                        size: 11, color: AppColors.accent.withValues(alpha: 0.6)),
                    const SizedBox(width: 2),
                    Text(
                      s.branchName!,
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.accent.withValues(alpha: 0.8)),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.services});

  final List<DoctorService> services;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.medical_services_outlined,
                size: 16, color: AppColors.success),
            SizedBox(width: 6),
            Text(
              'الخدمات',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: services.map((s) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.serviceName,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${s.price.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
