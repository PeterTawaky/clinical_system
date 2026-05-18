import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';
import 'package:clinical_application/features/settings/presentation/cubits/doctors_cubit.dart';
import 'package:clinical_application/features/settings/presentation/cubits/doctors_state.dart';
import 'package:clinical_application/features/settings/presentation/views/widgets/doctors/add_doctor_dialog_widget.dart';
import 'package:clinical_application/features/settings/presentation/views/widgets/doctors/doctor_card_widget.dart';
import 'package:clinical_application/features/settings/presentation/views/widgets/doctors/doctors_filter_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoctorsTabWidget extends StatefulWidget {
  const DoctorsTabWidget({super.key});

  @override
  State<DoctorsTabWidget> createState() => _DoctorsTabWidgetState();
}

class _DoctorsTabWidgetState extends State<DoctorsTabWidget> {
  final _nameFilter = ValueNotifier<String>('');
  final _branchFilter = ValueNotifier<String?>(null);
  final _specialtyFilter = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _nameFilter.dispose();
    _branchFilter.dispose();
    _specialtyFilter.dispose();
    super.dispose();
  }

  void _showAddDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<DoctorsCubit>()),
        ],
        child: const AddDoctorDialogWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DoctorsCubit, DoctorsState>(
      listener: (context, state) {
        if (state is DoctorsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.onError, size: 18),
                  const SizedBox(width: 8),
                  Text(state.message),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(onAdd: () => _showAddDialog(context)),
            const SizedBox(height: 16),
            BlocBuilder<DoctorsCubit, DoctorsState>(
              builder: (context, state) {
                return switch (state) {
                  DoctorsLoading() => const _LoadingIndicator(),
                  DoctorsLoaded s => _LoadedContent(
                      doctors: s.doctors,
                      branches: s.branches,
                      specialties: s.specialties,
                      nameFilter: _nameFilter,
                      branchFilter: _branchFilter,
                      specialtyFilter: _specialtyFilter,
                    ),
                  DoctorsActionLoading s => Column(
                      children: [
                        const LinearProgressIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.primaryContainer,
                        ),
                        const SizedBox(height: 8),
                        _DoctorsList(doctors: s.doctors),
                      ],
                    ),
                  DoctorsError s => _DoctorsList(doctors: s.doctors),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.medical_services_rounded,
              color: AppColors.onPrimary, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الأطباء',
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'إضافة وتعديل وحذف بيانات الأطباء',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('إضافة طبيب'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onPrimary,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({
    required this.doctors,
    required this.branches,
    required this.specialties,
    required this.nameFilter,
    required this.branchFilter,
    required this.specialtyFilter,
  });

  final List<Doctor> doctors;
  final List<String> branches;
  final List<String> specialties;
  final ValueNotifier<String> nameFilter;
  final ValueNotifier<String?> branchFilter;
  final ValueNotifier<String?> specialtyFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DoctorsFilterBarWidget(
          nameFilter: nameFilter,
          branchFilter: branchFilter,
          specialtyFilter: specialtyFilter,
          branches: branches,
          specialties: specialties,
        ),
        const SizedBox(height: 12),
        _FilteredDoctorsList(
          doctors: doctors,
          nameFilter: nameFilter,
          branchFilter: branchFilter,
          specialtyFilter: specialtyFilter,
        ),
      ],
    );
  }
}

class _FilteredDoctorsList extends StatelessWidget {
  const _FilteredDoctorsList({
    required this.doctors,
    required this.nameFilter,
    required this.branchFilter,
    required this.specialtyFilter,
  });

  final List<Doctor> doctors;
  final ValueNotifier<String> nameFilter;
  final ValueNotifier<String?> branchFilter;
  final ValueNotifier<String?> specialtyFilter;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable:
          Listenable.merge([nameFilter, branchFilter, specialtyFilter]),
      builder: (context, _) {
        final name = nameFilter.value.trim().toLowerCase();
        final branch = branchFilter.value;
        final specialty = specialtyFilter.value;

        final filtered = doctors.where((doc) {
          final matchName =
              name.isEmpty || doc.doctorName.toLowerCase().contains(name);
          final matchBranch =
              branch == null || doc.branches.contains(branch);
          final matchSpecialty =
              specialty == null || doc.specialty == specialty;
          return matchName && matchBranch && matchSpecialty;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultsCount(filtered: filtered.length, total: doctors.length),
            const SizedBox(height: 8),
            _DoctorsList(doctors: filtered),
          ],
        );
      },
    );
  }
}

class _ResultsCount extends StatelessWidget {
  const _ResultsCount({required this.filtered, required this.total});

  final int filtered;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Text(
      'النتائج: $filtered من $total',
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _DoctorsList extends StatelessWidget {
  const _DoctorsList({required this.doctors});

  final List<Doctor> doctors;

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.person_search_rounded,
                size: 48, color: AppColors.neutral300),
            SizedBox(height: 12),
            Text('لا توجد نتائج',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: doctors.length,
      itemBuilder: (context, index) =>
          DoctorCardWidget(doctor: doctors[index]),
    );
  }
}
