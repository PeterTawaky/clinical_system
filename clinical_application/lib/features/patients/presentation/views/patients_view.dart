import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

class PatientsView extends StatelessWidget {
  const PatientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_rounded, size: 64, color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'المرضى',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text('قيد التطوير', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
