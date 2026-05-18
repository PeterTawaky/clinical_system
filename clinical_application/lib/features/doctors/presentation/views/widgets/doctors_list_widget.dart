import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/doctors/presentation/views/widgets/doctor_view_card_widget.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';
import 'package:flutter/material.dart';

class DoctorsListWidget extends StatelessWidget {
  const DoctorsListWidget({super.key, required this.doctors});

  final List<Doctor> doctors;

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return const _EmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: doctors.length,
      itemBuilder: (context, index) =>
          DoctorViewCardWidget(doctor: doctors[index]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 56, color: AppColors.neutral300),
          SizedBox(height: 12),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'جرّب تغيير معايير البحث أو الفلاتر',
            style: TextStyle(fontSize: 13, color: AppColors.neutral300),
          ),
        ],
      ),
    );
  }
}
