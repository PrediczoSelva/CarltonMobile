import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../network/api_client.dart';

final GetIt getIt = GetIt.instance;

/// Registers app-wide singletons. Called once from `main.dart` before
/// `runApp`. Feature modules register their own repositories/blocs here
/// too, e.g. `getIt.registerFactory(() => FlightSearchBloc(getIt()));`
Future<void> setupDependencyInjection() async {
  // Storage
  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());

  // Networking
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt<FlutterSecureStorage>()));

  // --- Feature registrations go below as each module is built ---
  // getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()));
  // getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt()));
}
