import 'package:partiu/features/profile/presentation/viewmodels/image_upload_view_model.dart';

/// Service Locator simples para injeção de dependências
class ServiceLocator {
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();
  
  static final ServiceLocator _instance = ServiceLocator._internal();

  final Map<Type, Object> _dependencies = {};

  /// Inicializa as dependências
  void setup() {
    _dependencies[ImageUploadViewModel] = ImageUploadViewModel();
  }

  /// Obtém uma dependência do tipo especificado
  T get<T extends Object>() {
    final dep = _dependencies[T];
    if (dep == null) {
      throw Exception('Dependência $T não registrada no ServiceLocator');
    }
    return dep as T;
  }

  /// Registra uma dependência customizada
  void register<T extends Object>(T dependency) {
    _dependencies[T] = dependency;
  }

  /// Limpa todas as dependências
  void clear() {
    _dependencies.clear();
  }
}
