import 'package:dating_app/api/ranking_api_rest.dart';
import 'package:dating_app/screens/ranking/models/ranking_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum RankingType { local, global }

class RankingViewModel extends ChangeNotifier {
  RankingViewModel() : _api = RankingApiRest();

  final RankingApiRest _api;

  // Estado
  RankingEntry? _currentUserRanking;
  List<RankingEntry> _rankings = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _nextCursor;
  int _totalInRange = 0;

  // Cache para cada tipo de ranking (evita recarregar ao trocar tabs)
  final Map<String, _RankingCache> _cache = {};

  // Configurações
  RankingType _rankingType = RankingType.local;
  String _selectedCategory = 'All';
  Position? _userPosition;

  // Estado de busca
  List<RankingEntry>? _searchResults;
  String _searchQuery = '';

  // Getters
  RankingEntry? get currentUserRanking => _currentUserRanking;
  List<RankingEntry> get rankings => _rankings;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  int get totalInRange => _totalInRange;
  RankingType get rankingType => _rankingType;
  String get selectedCategory => _selectedCategory;
  bool get isSearching => _searchQuery.isNotEmpty;
  List<RankingEntry>? get searchResults => _searchResults;

  /// Inicializa com localização do usuário
  Future<void> initialize(Position? position) async {
    _userPosition = position;

    // Verifica TTL de 30 minutos
    final cacheKey = _getCacheKey();
    if (_cache.containsKey(cacheKey)) {
      final cache = _cache[cacheKey]!;
      final difference = DateTime.now().difference(cache.timestamp);
      
      if (difference.inMinutes < 30) {
        _loadFromCache(cacheKey);
        notifyListeners();
        return;
      }
    }

    await loadRankings(refresh: true);
  }

  /// Muda tipo de ranking (local/global)
  Future<void> changeRankingType(RankingType type) async {
    if (_rankingType == type) return;
    
    _rankingType = type;
    
    // Verifica se tem cache para essa tab
    final cacheKey = _getCacheKey();
    if (_cache.containsKey(cacheKey)) {
      final cache = _cache[cacheKey]!;
      final difference = DateTime.now().difference(cache.timestamp);
      
      if (difference.inMinutes < 30) {
        _loadFromCache(cacheKey);
        notifyListeners();
        return;
      }
    }
    
    // Limpa dados da tab anterior para evitar flash
    _rankings.clear();
    _currentUserRanking = null;
    _nextCursor = null;
    _hasMore = true;
    _errorMessage = null;
    
    notifyListeners(); // Mostra loading imediatamente
    await loadRankings(refresh: true);
  }

  /// Muda categoria selecionada
  Future<void> changeCategory(String category) async {
    if (_selectedCategory == category) return;
    
    // Limpa dados atuais imediatamente para evitar flash
    _rankings.clear();
    _currentUserRanking = null;
    _nextCursor = null;
    _hasMore = true;
    _errorMessage = null;
    
    _selectedCategory = category;
    
    // Limpa apenas cache da categoria anterior para essa tab
    final currentTabCacheKeys = _cache.keys.where((key) => key.startsWith(_rankingType.name)).toList();
    for (final key in currentTabCacheKeys) {
      _cache.remove(key);
    }
    
    notifyListeners(); // Notifica imediatamente para mostrar loading/empty
    await loadRankings(refresh: true);
  }

  /// Limpa todo o cache (usado no pull-to-refresh)
  void clearCache() {
    _cache.clear();
  }

  /// Gera chave de cache baseada em tipo e categoria
  String _getCacheKey() {
    return '${_rankingType.name}_$_selectedCategory';
  }

  /// Carrega dados do cache
  void _loadFromCache(String key) {
    final cache = _cache[key]!;
    _currentUserRanking = cache.currentUserRanking;
    _rankings = cache.rankings;
    _nextCursor = cache.nextCursor;
    _hasMore = cache.hasMore;
    _totalInRange = cache.totalInRange;
    _errorMessage = null;
  }

  /// Salva dados no cache
  void _saveToCache() {
    final key = _getCacheKey();
    _cache[key] = _RankingCache(
      currentUserRanking: _currentUserRanking,
      rankings: List.from(_rankings),
      nextCursor: _nextCursor,
      hasMore: _hasMore,
      totalInRange: _totalInRange,
      timestamp: DateTime.now(),
    );
  }



  /// Define resultados da busca
  void setSearchResults(String query, List<RankingEntry> results) {
    _searchQuery = query;
    _searchResults = results;
    notifyListeners();
  }

  /// Limpa busca
  void clearSearch() {
    _searchQuery = '';
    _searchResults = null;
    notifyListeners();
  }

  /// Carrega rankings (primeira página ou refresh)
  Future<void> loadRankings({bool refresh = false}) async {
    if (refresh) {
      _rankings.clear();
      _nextCursor = null;
      _hasMore = true;
      _errorMessage = null;
    }

    if (_isLoading || _isLoadingMore) return;

    _isLoading = refresh;
    if (!refresh) _isLoadingMore = true;
    
    notifyListeners();

    try {
      final response = _rankingType == RankingType.local
          ? await _loadLocalRankings()
          : await _loadGlobalRankings();
      
      // Handle both API response objects and direct Map responses
      Map<String, dynamic>? data;
      bool success = false;
      String? errorMessage;

      if (response is Map<String, dynamic>) {
        // Direct Map response (e.g., from _loadLocalRankings when no position)
        success = response['success'] == true;
        data = response['data'] as Map<String, dynamic>?;
        errorMessage = response['error'] as String?;
      } else {
        // API response object
        success = response.success;
        data = response.data;
        errorMessage = response.error?.message;
      }

      if (success && data != null) {
        // Ranking do usuário atual
        if (data['currentUserRanking'] != null) {
          _currentUserRanking = RankingEntry.fromMap(
            data['currentUserRanking'] as Map<String, dynamic>,
            isCurrentUser: true,
          );
        } else {
          _currentUserRanking = null;
        }

        // Lista de rankings
        final rankingsList = data['rankings'] as List<dynamic>? ?? [];
        final newRankings = rankingsList
            .map((r) => RankingEntry.fromMap(r as Map<String, dynamic>))
            .toList();

        if (refresh) {
          _rankings = newRankings;
        } else {
          _rankings.addAll(newRankings);
        }

        // Paginação
        final pagination = data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          _nextCursor = pagination['nextCursor'] as String?;
          _hasMore = pagination['hasMore'] == true;
          _totalInRange = pagination['totalInRange'] as int? ?? 0;
        }

        _errorMessage = null;
      } else {
        _errorMessage = errorMessage ?? 'Erro ao carregar ranking';
      }
      
      // Salva no cache após carregar com sucesso
      if (_errorMessage == null) {
        _saveToCache();
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar ranking: $e';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Carrega mais resultados (paginação)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _nextCursor == null) return;
    await loadRankings(refresh: false);
  }

  Future<dynamic> _loadLocalRankings() async {
    if (_userPosition == null) {
      // Retorna resposta vazia em vez de lançar exceção
      return {
        'success': false,
        'data': {
          'currentUserRanking': null,
          'rankings': <Map<String, dynamic>>[],
          'pagination': {
            'nextCursor': null,
            'hasMore': false,
            'totalInRange': 0,
          }
        },
        'error': 'Location permission denied or unavailable'
      };
    }

    return _api.getRankingLocal(
      latitude: _userPosition!.latitude,
      longitude: _userPosition!.longitude,
      radius: 100,
      category: _selectedCategory != 'All' ? _selectedCategory : null,
      limit: 10,
      cursor: _nextCursor,
    );
  }

  Future<dynamic> _loadGlobalRankings() async {
    return _api.getRankingGlobal(
      category: _selectedCategory != 'All' ? _selectedCategory : null,
      limit: 10,
      cursor: _nextCursor,
    );
  }
}

/// Cache para armazenar estado de cada tipo de ranking
class _RankingCache {
  _RankingCache({
    this.currentUserRanking,
    required this.rankings,
    this.nextCursor,
    required this.hasMore,
    required this.totalInRange,
    required this.timestamp,
  });

  final RankingEntry? currentUserRanking;
  final List<RankingEntry> rankings;
  final String? nextCursor;
  final bool hasMore;
  final int totalInRange;
  final DateTime timestamp;
}
