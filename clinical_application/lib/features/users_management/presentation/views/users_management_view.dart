import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/users_management/presentation/cubits/users_cubit.dart';
import 'package:clinical_application/features/users_management/presentation/cubits/users_state.dart';
import 'package:clinical_application/features/users_management/presentation/views/widgets/add_user_form_widget.dart';
import 'package:clinical_application/features/users_management/presentation/views/widgets/users_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersManagementView extends StatelessWidget {
  const UsersManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersCubit(),
      child: const _UsersManagementBody(),
    );
  }
}

class _UsersManagementBody extends StatelessWidget {
  const _UsersManagementBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<UsersCubit, UsersState>(
      listener: (context, state) {
        if (state is UsersError) {
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
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageHeader(),
              const SizedBox(height: 20),
              const AddUserFormWidget(),
              const SizedBox(height: 24),
              const _Divider(),
              const SizedBox(height: 20),
              BlocBuilder<UsersCubit, UsersState>(
                builder: (context, state) {
                  return switch (state) {
                    UsersLoading() => const _LoadingIndicator(),
                    UsersLoaded s => UsersListWidget(users: s.users),
                    UsersActionLoading s => Column(
                        children: [
                          const _ActionLoadingOverlay(),
                          UsersListWidget(users: s.users),
                        ],
                      ),
                    UsersError s => UsersListWidget(users: s.users),
                    _ => const SizedBox.shrink(),
                  };
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

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
      child: const Row(
        children: [
          Icon(Icons.manage_accounts_rounded,
              color: AppColors.onPrimary, size: 32),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة المستخدمين',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'إضافة وتعديل وحذف مستخدمي النظام',
                style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 13,
                ),
              ),
            ],
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
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _ActionLoadingOverlay extends StatelessWidget {
  const _ActionLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const LinearProgressIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.primaryContainer,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'قائمة المستخدمين',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
