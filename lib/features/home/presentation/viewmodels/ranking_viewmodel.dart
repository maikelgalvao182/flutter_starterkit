import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/data/models/locations_ranking_model.dart';
import 'package:partiu/features/home/data/services/locations_ranking_service.dart';
import 'package:partiu/features/home/data/services/user_location_service.dart';
import 'package:partiu/core/services/global_cache_service.dart';

/// Estados de carregamento
enum LoadState {
  idle,        // nunca carregou
  loading,     // carregando (inclusive pull-to-refresh)
  loaded,      // carregou com sucesso
  error,       // erro no carregamento
}

/// ViewModel para gerenciar estado do ranking
/// 
/// Responsabilidades:
/// - Carregar ranking de locais
/// - Gerenciar estado de loading e erros
/// - Filtrar por raio geográfico
/// - Fornecer dados limpos para a UI
class RankingViewModel extends ChangeNotifier {
  final LocationsRankingService _rankingService;
  final UserLocationService _locationService;
  final GlobalCacheService _cache = GlobalCacheService.instance;

  // Estado
  LoadState _loadState = LoadState.idle;
  String? _error;
  bool _refreshing = false;
  int _requestId = 0; // 🔒 Serialização de requests para evitar concorrência
  bool _isRefreshing = false; // 🔄 Flag para refresh explícito (pull-to-refresh)
  bool _initialized = false; // 🔒 Garantir que initialize() só rode uma vez

  // Dados
  List<LocationRankingModel> _locationRankings = [];

  // Filtros
  double? _userLat;
  double? _userLng;
  double _radiusKm = 30.0; // Raio padrão 30km
  bool _useRadiusFilter = false;

  RankingViewModel({
    LocationsRankingService? rankingService,
    UserLocationService? locationService,
  })  : _rankingService = rankingService ?? LocationsRankingService(),
        _locationService = locationService ?? UserLocationService();

  // Getters - Estado
  LoadState get loadState => _loadState;
  bool get isLoadingLocations => _loadState == LoadState.loading;
  bool get isLoading => _loadState == LoadState.loading;
  bool get isInitialLoading => _loadState == LoadState.loading && _locationRankings.isEmpty;
  bool get hasLoadedOnce => _loadState == LoadState.loaded || _loadState == LoadState.error;
  bool get isRefreshing => _isRefreshing;
  bool get shouldShowEmptyState => _loadState == LoadState.loaded && _locationRankings.isEmpty && !_isRefreshing;
  String? get error => _error;

  // Getters - Dados
  List<LocationRankingModel> get locationRankings => _locationRankings;

  // Getters - Filtros disponíveis
  List<String> get availableStates {
    return _locationRankings
        .map((loc) => loc.state)
        .where((e) => e != null && e.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList()
      ..sort();
  }

  List<String> get availableCities {
    return _locationRankings
        .map((loc) => loc.locality)
        .where((e) => e != null && e.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList()
      ..sort();
  }

  // Getters - Filtros
  double get radiusKm => _radiusKm;
  bool get useRadiusFilter => _useRadiusFilter;
  bool get hasLocation => _userLat != null && _userLng != null;

  /// Inicializa o ViewModel carregando localização e ranking de locais
  Future<void> initialize() async {
    // 🔒 REGRA 1: initialize() só pode rodar UMA VEZ
    if (_initialized) {
      debugPrint('🚫 [RankingViewModel] initialize() já executado - ignorando');
      return;
    }
    
    // 🔒 REGRA 1: Nunca rodar initialize durante refresh
    if (_isRefreshing) {
      debugPrint('🚫 [RankingViewModel] initialize() bloqueado durante refresh');
      return;
    }
    
    _initialized = true;
    debugPrint('🚀 [RankingViewModel] Inicializando (primeira vez)...');
    
    await _loadUserLocation();
    await loadLocationsRanking();
    
    debugPrint('✅ [RankingViewModel] Inicialização completa');
  }

  /// Carrega localização do usuário
  Future<void> _loadUserLocation() async {
    try {
      final result = await _locationService.getUserLocation();
      
      if (!result.hasError) {
        _userLat = result.location.latitude;
        _userLng = result.location.longitude;
        debugPrint('📍 Localização do usuário: $_userLat, $_userLng');
      }
    } catch (error) {
      debugPrint('⚠️ Não foi possível obter localização: $error');
    }
  }

  /// Carrega ranking de locais com cache global
  Future<void> loadLocationsRanking() async {
    // 🔒 Incrementa RequestId para detectar respostas antigas
    final requestId = ++_requestId;
    
    // 🔵 STEP 1: Tentar buscar do cache global primeiro
    final cacheKey = _buildLocationsCacheKey();
    final cached = _cache.get<List<LocationRankingModel>>(cacheKey);
    
    // 🔒 REGRA 2: refresh() NÃO pode usar cache - sempre forçar network
    if (cached != null && cached.isNotEmpty && !_isRefreshing) {
      debugPrint('🗂️ [LocationsRanking] Cache HIT - ${cached.length} locais');
      _locationRankings = cached;
      
      // 🔒 REGRA 3: loadState NÃO pode voltar para idle durante operação
      if (_loadState == LoadState.idle) {
        debugPrint('🟢 [LoadState] idle → loaded (cache hit)');
        _loadState = LoadState.loaded;
      }
      
      // 🔒 REGRA 4: Cache não notifica durante refresh
      if (!_isRefreshing) {
        notifyListeners();
      }
      
      // Atualização silenciosa em background
      _silentRefreshLocationsRanking();
      return;
    }
    
    if (_isRefreshing && cached != null) {
      debugPrint('🔄 [LocationsRanking] Refresh - ignorando cache, forçando network');
    }
    
    debugPrint('🗂️ [LocationsRanking] Cache MISS - carregando do Firestore');
    
    // 🚀 IMPORTANTE: Não limpar _locationRankings aqui para evitar flicker
    
    // 🔒 REGRA 3: loadState NÃO pode ser alterado durante refresh
    if (!_isRefreshing) {
      debugPrint('🔵 [LoadState] $_loadState → loading (iniciando fetch)');
      _loadState = LoadState.loading;
    } else {
      debugPrint('🔄 [Refresh] Mantendo loadState atual durante refresh: $_loadState');
    }
    
    _error = null;
    notifyListeners();

    try {
      final result = await _rankingService.getLocationsRanking(
        userLat: _useRadiusFilter ? _userLat : null,
        userLng: _useRadiusFilter ? _userLng : null,
        radiusKm: _useRadiusFilter ? _radiusKm : null,
      );
      
      // 🔒 Verificar se este request ainda é válido
      if (requestId != _requestId) {
        debugPrint('⚠️ [LocationsRanking] Request $requestId descartado (atual: $_requestId)');
        return; // Resposta antiga, ignora
      }
      
      _locationRankings = result;
      
      // 🔵 STEP 2: Salvar no cache global (TTL: 10 minutos)
      if (_locationRankings.isNotEmpty) {
        _cache.set(
          cacheKey,
          _locationRankings,
          ttl: const Duration(minutes: 10),
        );
        debugPrint('🗂️ [LocationsRanking] Cache SAVED - ${_locationRankings.length} locais');
      }
    } catch (error) {
      _error = 'Erro ao carregar ranking de locais';
      debugPrint('🔴 [LoadState] loading → error');
      _loadState = LoadState.error;
      debugPrint('❌ $_error: $error');
    } finally {
      // 🔒 REGRA 3: loadState NÃO pode ser alterado durante refresh
      if (_error == null && !_isRefreshing) {
        debugPrint('🟢 [LoadState] loading → loaded (fetch completo)');
        _loadState = LoadState.loaded;
      } else if (_error != null && !_isRefreshing) {
        debugPrint('🔴 [LoadState] loading → error (fetch falhou)');
        _loadState = LoadState.error;
      } else if (_isRefreshing) {
        debugPrint('🔄 [Refresh] LoadState preservado durante refresh: $_loadState');
      }
      
      notifyListeners();
      debugPrint('   - loadState FINAL: $_loadState');
      debugPrint('   - error: $_error');
      debugPrint('   - _locationRankings.length: ${_locationRankings.length}');
    }
  }

  /// Constrói chave de cache baseada nos filtros atuais
  String _buildLocationsCacheKey() {
    if (_useRadiusFilter && _userLat != null && _userLng != null) {
      return '${CacheKeys.rankingLocal}_${_radiusKm.toStringAsFixed(0)}km';
    }
    return CacheKeys.rankingGlobal;
  }

  /// Atualização silenciosa em background (não mostra loading)
  Future<void> _silentRefreshLocationsRanking() async {
    if (_refreshing) return;
    _refreshing = true;

    try {
      debugPrint('🔄 [LocationsRanking] Silent refresh iniciado');
      
      final fresh = await _rankingService.getLocationsRanking(
        userLat: _useRadiusFilter ? _userLat : null,
        userLng: _useRadiusFilter ? _userLng : null,
        radiusKm: _useRadiusFilter ? _radiusKm : null,
      );

      // Comparar com cache atual usando método dedicado
      if (_hasRankingChanged(fresh, _locationRankings)) {
        debugPrint('🔄 [LocationsRanking] Dados atualizados detectados');
        _locationRankings = fresh;
        
        // Atualizar cache (usa TTL default do método set)
        final cacheKey = _buildLocationsCacheKey();
        _cache.set(
          cacheKey,
          fresh,
          ttl: const Duration(minutes: 10),
        );
        
        notifyListeners();
      } else {
        debugPrint('🔄 [LocationsRanking] Nenhuma mudança detectada');
      }
    } catch (e) {
      debugPrint('⚠️ [LocationsRanking] Erro no silent refresh: $e');
      // Não exibe erro ao usuário
    } finally {
      _refreshing = false;
    }
  }

  /// Verifica se houve mudanças no ranking comparando placeId e score
  bool _hasRankingChanged(
    List<LocationRankingModel> fresh,
    List<LocationRankingModel> old,
  ) {
    if (fresh.length != old.length) return true;

    for (int i = 0; i < fresh.length; i++) {
      if (fresh[i].placeId != old[i].placeId ||
          fresh[i].totalEventsHosted != old[i].totalEventsHosted) {
        return true;
      }
    }
    return false;
  }

  /// Alterna filtro de raio
  Future<void> toggleRadiusFilter() async {
    _useRadiusFilter = !_useRadiusFilter;
    debugPrint('🔘 Filtro de raio: ${_useRadiusFilter ? 'ATIVADO' : 'DESATIVADO'}');
    
    notifyListeners();
    await loadLocationsRanking();
  }

  /// Atualiza raio de busca
  Future<void> updateRadius(double newRadiusKm) async {
    if (_radiusKm == newRadiusKm) return;
    
    _radiusKm = newRadiusKm;
    debugPrint('📏 Raio atualizado: $_radiusKm km');
    
    if (_useRadiusFilter) {
      notifyListeners();
      await loadLocationsRanking();
    }
  }

  /// Recarrega rankings forçando busca na network (nunca usa cache)
  /// 🔒 REGRA 2: refresh() = forçar network, sempre
  Future<void> refresh() async {
    debugPrint('🔄 [RankingViewModel] refresh() chamado');
    debugPrint('   - ANTES: loadState = $_loadState');
    debugPrint('   - ANTES: _locationRankings.length = ${_locationRankings.length}');
    debugPrint('   - ANTES: _isRefreshing = $_isRefreshing');
    
    _isRefreshing = true;
    notifyListeners();
    
    try {
      // 🚀 REFRESH = apenas recarregar dados, nunca initialize()
      await loadLocationsRanking(); // Força network devido ao _isRefreshing = true
      
      debugPrint('✅ [RankingViewModel] refresh() dados atualizados');
    } catch (error) {
      debugPrint('❌ [RankingViewModel] refresh() erro: $error');
      _error = 'Erro ao atualizar ranking';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
    
    debugPrint('🔄 [RankingViewModel] refresh() completo');
    debugPrint('   - DEPOIS: loadState = $_loadState');
    debugPrint('   - DEPOIS: _locationRankings.length = ${_locationRankings.length}');
    debugPrint('   - DEPOIS: _isRefreshing = $_isRefreshing');
  }
}