import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:partiu/shared/repositories/auth_repository.dart';
import 'package:partiu/shared/repositories/auth_repository_interface.dart';
import 'package:partiu/features/auth/presentation/controllers/sign_in_view_model.dart';
import 'package:partiu/features/auth/presentation/controllers/email_auth_view_model.dart';
import 'package:partiu/features/auth/presentation/controllers/cadastro_view_model.dart';
import 'package:partiu/features/location/data/repositories/location_repository.dart';
import 'package:partiu/features/location/domain/repositories/location_repository_interface.dart';
import 'package:partiu/features/location/presentation/viewmodels/update_location_view_model.dart';

/// Sistema de injeção de dependências usando get_it
class DependencyProvider extends InheritedWidget {
  const DependencyProvider({
    super.key,
    required super.child,
    required this.serviceLocator,
  });

  final ServiceLocator serviceLocator;

  static DependencyProvider of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<DependencyProvider>();
    assert(result != null, 'No DependencyProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(DependencyProvider oldWidget) => false;
}

/// Service Locator usando get_it
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final GetIt _getIt = GetIt.instance;

  /// Inicializa todas as dependências
  Future<void> init() async {
    // Repositories
    _getIt.registerLazySingleton<IAuthRepository>(() => AuthRepository());
    _getIt.registerLazySingleton<LocationRepositoryInterface>(() => LocationRepository());

    // ViewModels
    _getIt.registerFactory<SignInViewModel>(
      () => SignInViewModel(authRepository: _getIt<IAuthRepository>()),
    );
    _getIt.registerFactory<EmailAuthViewModel>(() => EmailAuthViewModel());
    _getIt.registerFactory<CadastroViewModel>(() => CadastroViewModel());
    _getIt.registerFactory<UpdateLocationViewModel>(
      () => UpdateLocationViewModel(locationRepository: _getIt<LocationRepositoryInterface>()),
    );
  }

  T get<T extends Object>() => _getIt.get<T>();

  void register<T extends Object>(T instance) {
    if (!_getIt.isRegistered<T>()) {
      _getIt.registerSingleton<T>(instance);
    }
  }
}
