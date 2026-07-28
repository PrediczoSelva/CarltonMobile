import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource_impl.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final GetIt getIt = GetIt.instance;

/// Registers app-wide singletons. Called once from `main.dart` before
/// `runApp`. Feature modules register their own repositories/blocs here
/// too, e.g. `getIt.registerFactory(() => FlightSearchBloc(getIt()));`
Future<void> setupDependencyInjection() async {
  // Storage (used for user preferences, non-auth data)
  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());

  // Networking
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());

  // Auth
  getIt.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDatasource: getIt<AuthRemoteDatasource>(),
      secureStorage: getIt<FlutterSecureStorage>(),
    ),
  );
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
}