import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/examinations/presentation/cubits/book_exam_cubit.dart';
import 'package:clinical_application/features/examinations/presentation/cubits/book_exam_state.dart';
import 'package:clinical_application/features/examinations/presentation/views/widgets/book_exam_filters_widget.dart';
import 'package:clinical_application/features/examinations/presentation/views/widgets/doctor_schedule_table_widget.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookExamTabWidget extends StatefulWidget {
  const BookExamTabWidget({super.key});

  @override
  State<BookExamTabWidget> createState() => _BookExamTabWidgetState();
}

class _BookExamTabWidgetState extends State<BookExamTabWidget> {
  final _nameFilter = ValueNotifier<String>('');
  final _specialtyFilter = ValueNotifier<String?>(null);
  final _branchFilter = ValueNotifier<String?>(null);
  final _dayFilter = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _nameFilter.dispose();
    _specialtyFilter.dispose();
    _branchFilter.dispose();
    _dayFilter.dispose();
    super.dispose();
  }

  List<Doctor> _applyFilters(List<Doctor> doctors) {
    return doctors.where((d) {
      final name = _nameFilter.value.trim().toLowerCase();
      if (name.isNotEmpty && !d.doctorName.toLowerCase().contains(name)) {
        return false;
      }
      final specialty = _specialtyFilter.value;
      if (specialty != null && d.specialty != specialty) {
        return false;
      }
      final branch = _branchFilter.value;
      if (branch != null && !d.branches.contains(branch)) {
        return false;
      }
      final day = _dayFilter.value;
      if (day != null) {
        final hasDay = d.schedules.any((s) => s.dayOfWeek == day);
        if (!hasDay) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookExamCubit, BookExamState>(
      builder: (context, state) {
        if (state is BookExamLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is BookExamError) {
          return _ErrorWidget(
            message: state.message,
            onRetry: () => context.read<BookExamCubit>().load(),
          );
        }
        if (state is BookExamLoaded) {
          return _BookExamContent(
            state: state,
            nameFilter: _nameFilter,
            specialtyFilter: _specialtyFilter,
            branchFilter: _branchFilter,
            dayFilter: _dayFilter,
            applyFilters: _applyFilters,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BookExamContent extends StatelessWidget {
  const _BookExamContent({
    required this.state,
    required this.nameFilter,
    required this.specialtyFilter,
    required this.branchFilter,
    required this.dayFilter,
    required this.applyFilters,
  });

  final BookExamLoaded state;
  final ValueNotifier<String> nameFilter;
  final ValueNotifier<String?> specialtyFilter;
  final ValueNotifier<String?> branchFilter;
  final ValueNotifier<String?> dayFilter;
  final List<Doctor> Function(List<Doctor>) applyFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          BookExamFiltersWidget(
            nameFilter: nameFilter,
            specialtyFilter: specialtyFilter,
            branchFilter: branchFilter,
            dayFilter: dayFilter,
            branches: state.branches.map((b) => b.branchName).toList(),
            specialties: state.specialties,
            hasBranches: state.branches.isNotEmpty,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: nameFilter,
              builder: (context, _, _a) => ValueListenableBuilder<String?>(
                valueListenable: specialtyFilter,
                builder: (context, _, _b) => ValueListenableBuilder<String?>(
                  valueListenable: branchFilter,
                  builder: (context, _, _c) => ValueListenableBuilder<String?>(
                    valueListenable: dayFilter,
                    builder: (context, _, _d) {
                      final filtered = applyFilters(state.doctors);
                      if (filtered.isEmpty) {
                        return const _EmptyDoctors();
                      }
                      return DoctorScheduleTableWidget(
                        doctors: filtered,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDoctors extends StatelessWidget {
  const _EmptyDoctors();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 56, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('لا توجد نتائج', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
