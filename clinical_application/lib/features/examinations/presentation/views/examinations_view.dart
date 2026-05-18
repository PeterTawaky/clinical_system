import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/examinations/presentation/cubits/book_exam_cubit.dart';
import 'package:clinical_application/features/examinations/presentation/cubits/exams_list_cubit.dart';
import 'package:clinical_application/features/examinations/presentation/views/widgets/book_exam_tab_widget.dart';
import 'package:clinical_application/features/examinations/presentation/views/widgets/exams_list_tab_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExaminationsView extends StatelessWidget {
  const ExaminationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          _ExaminationsTabBar(),
          const Expanded(child: _ExaminationsTabBarView()),
        ],
      ),
    );
  }
}

class _ExaminationsTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: const TabBar(
        indicatorColor: AppColors.onPrimary,
        indicatorWeight: 3,
        labelColor: AppColors.onPrimary,
        unselectedLabelColor: Color(0xAAFFFFFF),
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: 'حجز الكشوفات'),
          Tab(text: 'الكشوفات المؤقتة'),
          Tab(text: 'الكشوفات المؤكدة'),
          Tab(text: 'الكشوفات الملغية'),
        ],
      ),
    );
  }
}

class _ExaminationsTabBarView extends StatelessWidget {
  const _ExaminationsTabBarView();

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        BlocProvider(
          create: (_) => BookExamCubit(),
          child: const BookExamTabWidget(),
        ),
        BlocProvider(
          create: (_) => ExamsListCubit('مؤقت'),
          child: const ExamsListTabWidget(
            status: 'مؤقت',
            showActions: true,
          ),
        ),
        BlocProvider(
          create: (_) => ExamsListCubit('مؤكد'),
          child: const ExamsListTabWidget(
            status: 'مؤكد',
            showActions: false,
          ),
        ),
        BlocProvider(
          create: (_) => ExamsListCubit('ملغي'),
          child: const ExamsListTabWidget(
            status: 'ملغي',
            showActions: false,
          ),
        ),
      ],
    );
  }
}
