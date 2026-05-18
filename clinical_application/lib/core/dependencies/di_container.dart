import 'package:clinical_application/core/services/networking/api_consumer.dart';
import 'package:clinical_application/core/services/networking/dio_consumer.dart';
import 'package:clinical_application/features/auth/presentation/cubits/login_cubit.dart';
import 'package:get_it/get_it.dart';

final GetIt serviceLocator = GetIt.instance;

void setupDI() {
  serviceLocator.registerLazySingleton<ApiConsumer>(() => DioConsumer());
  serviceLocator.registerFactory<LoginCubit>(() => LoginCubit(serviceLocator()));
}
