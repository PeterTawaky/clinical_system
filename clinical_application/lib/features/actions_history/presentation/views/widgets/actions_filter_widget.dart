import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/actions_history/presentation/cubits/actions_cubit.dart';
import 'package:clinical_application/features/actions_history/presentation/cubits/actions_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActionsFilterWidget extends StatelessWidget {
  const ActionsFilterWidget({super.key, required this.showingMineOnly});

  final bool showingMineOnly;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'جميع الإجراءات',
          icon: Icons.public_rounded,
          selected: !showingMineOnly,
          onTap: () => context.read<ActionsCubit>().loadAll(),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'إجراءاتي فقط',
          icon: Icons.person_rounded,
          selected: showingMineOnly,
          onTap: () => context.read<ActionsCubit>().loadMine(),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppColors.primary : AppColors.neutral500,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
