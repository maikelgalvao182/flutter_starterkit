import 'package:partiu/features/home/presentation/viewmodels/apple_map_viewmodel.dart';

/// Serviço responsável por inicializar dados globais antes do app abrir
class AppInitializerService {
  final AppleMapViewModel mapViewModel;

  AppInitializerService(this.mapViewModel);

  /// Executa toda a inicialização necessária
  Future<void> initialize() async {
    // Apenas preload de pins (imagens)
    // Os eventos serão carregados quando o AppleMapView estiver pronto
    await mapViewModel.initialize();
  }
}
