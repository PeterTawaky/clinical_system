import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/home/presentation/views/widgets/drawer_header_widget.dart';
import 'package:clinical_application/features/home/presentation/views/widgets/drawer_item_widget.dart';
import 'package:flutter/material.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onLogout,
  });

  final List<({IconData icon, String label})> items;
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          const DrawerHeaderWidget(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) => DrawerItemWidget(
                icon: items[index].icon,
                label: items[index].label,
                isSelected: selectedIndex == index,
                onTap: () => onItemTap(index),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          _LogoutTile(onLogout: onLogout),
        ],
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListTile(
        leading: const Icon(
          Icons.logout_rounded,
          color: AppColors.error,
          size: 22,
        ),
        title: const Text(
          'تسجيل الخروج',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        onTap: onLogout,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        hoverColor: AppColors.errorContainer,
      ),
    );
  }
}
