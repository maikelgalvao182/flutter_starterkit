import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/data/models/locations_ranking_model.dart';
import 'package:partiu/features/home/data/services/locations_ranking_service.dart';
import 'package:partiu/features/home/data/services/user_location_service.dart';
import 'package:partiu/core/services/global_cache_service.dart';

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
  bool _isLoadingLocations = false;
  String? _error;
  bool _refreshing = false;

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
  bool get isLoadingLocations => _isLoadingLocations;
  bool get isLoading => _isLoadingLocations;
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

  /// Inicializa o ViewModel carregando localização e rankings
  /// Inicializa o ViewModel carregando localização e ranking de locais
  Future<void> initialize() async {
    await _loadUserLocation();
    await loadLocationsRanking();
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
    // 🔵 STEP 1: Tentar buscar do cache global primeiro
    final cacheKey = _buildLocationsCacheKey();
    final cached = _cache.get<List<LocationRankingModel>>(cacheKey);
    
    if (cached != null && cached.isNotEmpty) {
      debugPrint('🗂️ [LocationsRanking] Cache HIT - ${cached.length} locais');
      _locationRankings = cached;
      _isLoadingLocations = false;
      notifyListeners();
      
      // Atualização silenciosa em background
      _silentRefreshLocationsRanking();
      return;
    }
    
    debugPrint('🗂️ [LocationsRanking] Cache MISS - carregando do Firestore');
    
    _isLoadingLocations = true;
    _error = null;
    notifyListeners();

    try {
      _locationRankings = await _rankingService.getLocationsRanking(
        userLat: _useRadiusFilter ? _userLat : null,
        userLng: _useRadiusFilter ? _userLng : null,
        radiusKm: _useRadiusFilter ? _radiusKm : null,
      );
      
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
      debugPrint('❌ $_error: $error');
    } finally {
      _isLoadingLocations = false;
      notifyListeners();
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

  /// Recarrega todos os rankings
  Future<void> refresh() async {
    await initialize();
  }
}