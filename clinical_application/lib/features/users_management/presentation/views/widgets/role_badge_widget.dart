import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/users_management/data/models/system_user_model.dart';
import 'package:flutter/material.dart';

class RoleBadgeWidget extends StatelessWidget {
  const RoleBadgeWidget({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 13, color: _fgColor),
          const SizedBox(width: 4),
          Text(
            role.label,
            style: TextStyle(
              color: _fgColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
