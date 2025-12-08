import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/presentation/viewmodels/map_viewmodel.dart';
import 'package:partiu/core/services/block_service.dart';
import 'package:partiu/common/state/app_state.dart';

/// Serviço responsável por inicializar dados globais antes do app abrir
class AppInitializerService {
  final MapViewModel mapViewModel;

  AppInitializerService(this.mapViewModel);

  /// Executa toda a inicialização necessária
  /// 
  /// Fluxo de inicialização:
  /// 1. Inicializa cache de bloqueios (BlockService)
  /// 2. Pré-carrega pins (imagens dos markers)
  /// 3. Obtém localização do usuário
  /// 4. Carrega eventos próximos
  /// 5. Enriquece eventos com distância/disponibilidade/restrições de idade
  /// 6. PRÉ-CARREGA imagens dos markers (cache)
  /// 
  /// NOTA: Os markers pré-carregados servem apenas para popular o cache de imagens.
  /// O GoogleMapView regenerará os markers com os callbacks corretos.
  /// 
  /// ✅ RESTRIÇÕES DE IDADE: Pré-calculadas no _enrichEvents do MapViewModel
  /// para eliminar flash no botão do EventCard
  /// 
  /// Quando este método terminar, o mapa já estará pronto para exibir
  Future<void> initialize() async {
    try {
      debugPrint('🚀 [AppInitializer] Iniciando bootstrap do app...');
      
      // 1. Inicializa o cache de bloqueios
      final currentUserId = AppState.currentUserId;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        debugPrint('🔒 [AppInitializer] Inicializando BlockService...');
        await BlockService().initialize(currentUserId);
        debugPrint('✅ [AppInitializer] BlockService inicializado');
      } else {
        debugPrint('⚠️ [AppInitializer] BlockService não inicializado (usuário não autenticado)');
      }
      
      // 2. Inicializa o ViewModel (preload de pins + carrega eventos)
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
