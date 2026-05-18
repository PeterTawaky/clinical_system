import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/actions_history/data/models/action_model.dart';
import 'package:flutter/material.dart';

class ActionCardWidget extends StatelessWidget {
  const ActionCardWidget({super.key, required this.action});

  final ActionModel action;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolveIcon(action.description);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionIconBubble(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionInfo(action: action),
          ),
          _ActionDate(dateStr: action.actionDate),
        ],
      ),
    );
  }

  static (IconData, Color) _resolveIcon(String desc) {
    if (desc.contains('دخول')) return (Icons.login_rounded, AppColors.success);
    if (desc.contains('خروج')) return (Icons.logout_rounded, AppColors.neutral500);
    if (desc.contains('طبيب')) return (Icons.medical_services_rounded, AppColors.secondary);
    if (desc.contains('مريض')) return (Icons.person_rounded, AppColors.info);
    if (desc.contains('كشف') || desc.contains('فحص')) return (Icons.assignment_rounded, AppColors.warning);
    if (desc.contains('مستخدم')) return (Icons.manage_accounts_rounded, AppColors.primary);
    if (desc.contains('حذف')) return (Icons.delete_rounded, AppColors.error);
    if (desc.contains('تعديل') || desc.contains('تحديث')) return (Icons.edit_rounded, AppColors.secondary);
    if (desc.contains('إضافة') || desc.contains('إنشاء')) return (Icons.add_circle_rounded, AppColors.success);
    return (Icons.history_rounded, AppColors.accent);
  }
}

class _ActionIconBubble extends StatelessWidget {
  const _ActionIconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ActionInfo extends StatelessWidget {
  const _ActionInfo({required this.action});

  final ActionModel action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          action.description,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.person_outline_rounded,
                size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              action.username,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionDate extends StatelessWidget {
  const _ActionDate({required this.dateStr});

  final String? dateStr;

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(dateStr),
      textAlign: TextAlign.end,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.textMuted,
        height: 1.6,
      ),
    );
  }

  String _format(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$d/$mo/${dt.year}\n$h:$mi';
    } catch (_) {
      return raw;
    }
  }
}
