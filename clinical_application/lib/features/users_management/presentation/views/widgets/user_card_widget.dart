import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/users_management/data/models/system_user_model.dart';
import 'package:clinical_application/features/users_management/presentation/cubits/users_cubit.dart';
import 'package:clinical_application/features/users_management/presentation/views/widgets/edit_user_dialog_widget.dart';
import 'package:clinical_application/features/users_management/presentation/views/widgets/role_badge_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserCardWidget extends StatelessWidget {
  const UserCardWidget({super.key, required this.user, required this.index});

  final SystemUser user;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        children: [
          _UserAvatar(role: user.role),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                RoleBadgeWidget(role: user.role),
              ],
            ),
          ),
          _CardActions(user: user),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(_icon, color: _fgColor, size: 22),
    );
  }

  Color get _bgColor {
    switch (role) {
      case UserRole.manager:
        return AppColors.primaryContainer;
      case UserRole.accountant:
        return AppColors.warningContainer;
      case UserRole.user:
        return AppColors.secondaryContainer;
    }
  }

  Color get _fgColor {
    switch (role) {
      case UserRole.manager:
        return AppColors.primary;
      case UserRole.accountant:
        return AppColors.warning;
      case UserRole.user:
        return AppColors.secondary;
    }
  }

  IconData get _icon {
    switch (role) {
      case UserRole.manager:
        return Icons.admin_panel_settings_rounded;
      case UserRole.accountant:
        return Icons.calculate_rounded;
      case UserRole.user:
        return Icons.person_rounded;
    }
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({required this.user});

  final SystemUser user;

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<UsersCubit>(),
        child: _DeleteConfirmDialog(user: user),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<UsersCubit>(),
        child: EditUserDialogWidget(user: user),
      ),
    );
  }

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
            minimumSize: const Size(36, 36),
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _confirmDelete(context),
          icon: const Icon(Icons.delete_rounded, size: 20),
          color: AppColors.error,
          tooltip: 'حذف',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.errorContainer,
            minimumSize: const Size(36, 36),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.user});

  final SystemUser user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_rounded, color: AppColors.error, size: 22),
          SizedBox(width: 8),
          Text(
            'حذف المستخدم',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          children: [
            const TextSpan(text: 'هل أنت متأكد من حذف المستخدم '),
            TextSpan(
              text: user.username,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const TextSpan(text: '؟\nلا يمكن التراجع عن هذا الإجراء.'),
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
            context.read<UsersCubit>().deleteUser(user.id);
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
    );
  }
}
