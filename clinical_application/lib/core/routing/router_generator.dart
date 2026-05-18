import 'package:clinical_application/core/errors/router_error_view.dart';
import 'package:clinical_application/core/routing/app_routes.dart';
import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/auth/presentation/views/login_view.dart';
import 'package:clinical_application/features/home/presentation/views/home_view.dart';
import 'package:go_router/go_router.dart';

class RouterGenerator {
  static GoRouter mainRouting = GoRouter(
    initialLocation: AppRoutes.loginView,
    errorBuilder: (context, state) {
      return RouterErrorView(primaryColor: AppColors.primary);
    },
    routes: [
      GoRoute(
        name: AppRoutes.homeView,
        path: AppRoutes.homeView,
        builder: (context, state) => HomeView(),
      ),
      GoRoute(
        name: AppRoutes.loginView,
        path: AppRoutes.loginView,
        builder: (context, state) => const LoginView(),
      ),
    ],
  );
}
