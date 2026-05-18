import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

class FinanceStatsBarWidget extends StatelessWidget {
  const FinanceStatsBarWidget({super.key, required this.stats});

  final List<FinanceStatItem> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: stats
              .map((s) => Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: _StatChip(item: s),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class FinanceStatItem {
  const FinanceStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.item});

  final FinanceStatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: item.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 16, color: item.color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  color: item.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 13,
                  color: item.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
