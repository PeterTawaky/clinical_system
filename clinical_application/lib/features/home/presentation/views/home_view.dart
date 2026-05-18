import 'package:clinical_application/core/routing/app_routes.dart';
import 'package:clinical_application/core/services/action_logger.dart';
import 'package:clinical_application/core/services/app_session.dart';
import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/actions_history/presentation/views/actions_history_view.dart';
import 'package:clinical_application/features/examinations/presentation/views/examinations_view.dart';
import 'package:clinical_application/features/finance/presentation/views/finance_view.dart';
import 'package:clinical_application/features/home/presentation/views/widgets/dashboard_widget.dart';
import 'package:clinical_application/features/home/presentation/views/widgets/home_drawer.dart';
import 'package:clinical_application/features/patients/presentation/views/patients_view.dart';
import 'package:clinical_application/features/settings/presentation/views/settings_view.dart';
import 'package:clinical_application/features/users_management/presentation/views/users_management_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);

  static const List<({IconData icon, String label})> _drawerItems = [
    // (icon: Icons.dashboard_rounded, label: 'الرئيسية'),
    (icon: Icons.settings_rounded, label: 'الإعدادات'),
    // (icon: Icons.people_rounded, label: 'المرضى'),
    (icon: Icons.assignment_rounded, label: 'الكشوفات'),
    (icon: Icons.account_balance_wallet_rounded, label: 'الماليات'),
    (icon: Icons.manage_accounts_rounded, label: 'إدارة المستخدمين'),
    (icon: Icons.history_rounded, label: 'سجل الإجراءات'),
  ];

  static const List<Widget> _pages = [
    // DashboardWidget(),
    SettingsView(),
    // PatientsView(),
    ExaminationsView(),
    FinanceView(),
    UsersManagementView(),
    ActionsHistoryView(),
  ];

  void _onItemTap(int index) {
    _selectedIndex.value = index;
    Navigator.pop(context);
  }

  Future<void> _onLogout() async {
    Navigator.pop(context);
    await ActionLogger.log('تسجيل الخروج');
    AppSession.clear();
    if (mounted) context.go(AppRoutes.loginView);
  }

  @override
  void dispose() {
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedIndex,
      builder: (context, index, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            title: Text(
              _drawerItems[index].label,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: AppColors.onPrimary),
            elevation: 0,
          ),
          drawer: HomeDrawer(
            items: _drawerItems,
            selectedIndex: index,
            onItemTap: _onItemTap,
            onLogout: _onLogout,
          ),
          body: _pages[index],
        );
      },
    );
  }
}
