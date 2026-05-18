import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/users_management/data/models/system_user_model.dart';
import 'package:clinical_application/features/users_management/presentation/views/widgets/user_card_widget.dart';
import 'package:flutter/material.dart';

class UsersListWidget extends StatelessWidget {
  const UsersListWidget({super.key, required this.users});

  final List<SystemUser> users;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ListHeader(count: users.length),
        const SizedBox(height: 12),
        if (users.isEmpty)
          const _EmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) => UserCardWidget(
              user: users[index],
              index: index,
            ),
          ),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.group_rounded,
              color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'المستخدمون الحاليون',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count مستخدم',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.group_off_rounded, size: 48, color: AppColors.neutral300),
          SizedBox(height: 12),
          Text(
            'لا يوجد مستخدمون بعد',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
