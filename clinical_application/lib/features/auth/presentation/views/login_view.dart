import 'package:clinical_application/core/dependencies/di_container.dart';
import 'package:clinical_application/core/routing/app_routes.dart';
import 'package:clinical_application/core/services/action_logger.dart';
import 'package:clinical_application/core/services/app_session.dart';
import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/core/utils/extensions/context_extensions.dart';
import 'package:clinical_application/features/auth/presentation/cubits/login_cubit.dart';
import 'package:clinical_application/features/auth/presentation/views/widgets/login_brand_panel_widget.dart';
import 'package:clinical_application/features/auth/presentation/views/widgets/login_form_widget.dart';
import 'package:clinical_application/features/auth/presentation/views/widgets/login_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<LoginCubit>(),
      child: Scaffold(
        body: BlocListener<LoginCubit, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              AppSession.start(state.username, state.role);
              ActionLogger.log('تسجيل الدخول');
              context.go(AppRoutes.homeView);
            } else if (state is LoginFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          child: Row(
            children: [
              if (!context.isMobileSize)
                const Expanded(flex: 2, child: LoginBrandPanelWidget()),
              Expanded(
                flex: 3,
                child: _FormPanelWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormPanelWidget extends StatelessWidget {
  const _FormPanelWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LoginHeaderWidget(),
                SizedBox(height: 40),
                LoginFormWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
