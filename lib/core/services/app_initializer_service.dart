import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/presentation/viewmodels/map_viewmodel.dart';

/// Serviço responsável por inicializar dados globais antes do app abrir
class AppInitializerService {
  final MapViewModel mapViewModel;

  AppInitializerService(this.mapViewModel);

  /// Executa toda a inicialização necessária
  /// 
  /// Fluxo de inicialização:
  /// 1. Pré-carrega pins (imagens dos markers)
  /// 2. Obtém localização do usuário
  /// 3. Carrega eventos próximos
  /// 4. Enriquece eventos com distância/disponibilidade
  /// 5. PRÉ-CARREGA imagens dos markers (cache)
  /// 
  /// NOTA: Os markers pré-carregados servem apenas para popular o cache de imagens.
  /// O GoogleMapView regenerará os markers com os callbacks corretos.
  /// 
  /// Quando este método terminar, o mapa já estará pronto para exibir
  Future<void> initialize() async {
    try {
      debugPrint('🚀 [AppInitializer] Iniciando bootstrap do app...');
      
      // Inicializa o ViewModel (preload de pins + carrega eventos)
      // O initialize() do ViewModel já chama loadNearbyEvents() internamente
      // que também gera os markers (populando o cache de imagens)
      await mapViewModel.initialize();
      
      debugPrint('✅ [AppInitializer] Bootstrap completo!');
      debugPrint('📊 [AppInitializer] Eventos carregados: ${mapViewModel.events.length}');
      debugPrint('📍 [AppInitializer] Markers gerados (cache): ${mapViewModel.googleMarkers.length}');
      debugPrint('🗺️ [AppInitializer] Mapa pronto: ${mapViewModel.mapReady}');
      debugPrint('ℹ️ [AppInitializer] Markers serão regenerados com callbacks no GoogleMapView');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [AppInitializer] Erro durante inicialização: $e');
      debugPrint('Stack trace: $stackTrace');
      // Não lançar erro - deixar app abrir mesmo com falha
      // O ViewModel tentará carregar novamente quando o mapa estiver pronto
    }
  }
}
