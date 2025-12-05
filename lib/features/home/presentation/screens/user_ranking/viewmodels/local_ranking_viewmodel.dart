import 'package:dating_app/api/core/api_response.dart';
import 'package:dating_app/api/ranking_api_rest.dart';
import 'package:dating_app/screens/ranking/models/ranking_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// ViewModel específico para Ranking Local
/// 
/// Responsabilidades:
/// - Gerenciar estado do ranking local (100km do usuário)
/// - Cache isolado para não interferir com ranking global
/// - Tratamento de permissão de localização
class LocalRankingViewModel extends ChangeNotifier {
  final RankingApiRest _api = RankingApiRest();
  
  // Estado
  List<RankingEntry> _rankings = [];
  RankingEntry? _currentUserRanking;
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasMore = true;
  String? _nextCursor;
  String? _errorMessage;
  int _totalInRange = 0;
  Position? _userPosition;
  
  // Cache local isolado
  final Map<String, _LocalRankingCache> _cache = {};
  
  // Getters
  List<RankingEntry> get rankings => List.unmodifiable(_rankings);
  RankingEntry? get currentUserRanking => _currentUserRanking;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  int get totalInRange => _totalInRange;
  bool get hasPosition => _userPosition != null;
  
  /// Inicializa com localização do usuário
  Future<void> initialize(Position? position) async {
    _userPosition = position;
    
    // Verifica cache para categoria atual
    final cacheKey = _selectedCategory;
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
  
  /// Muda categoria selecionada
  Future<void> changeCategory(String category) async {
    if (_selectedCategory == category) return;
    
    // Limpa dados atuais imediatamente
    _rankings.clear();
    _currentUserRanking = null;
    _nextCursor = null;
    _hasMore = true;
    _errorMessage = null;
    
    _selectedCategory = category;
    
    // Verifica se tem cache para nova categoria
    if (_cache.containsKey(category)) {
      final cache = _cache[category]!;
      final difference = DateTime.now().difference(cache.timestamp);
      
      if (difference.inMinutes < 30) {
        _loadFromCache(category);
        notifyListeners();
        return;
      }
    }
    
    notifyListeners(); // Mostra loading
    await loadRankings(refresh: true);
  }
  
  /// Carrega rankings locais
  Future<void> loadRankings({bool refresh = false}) async {
    
    // [FIX] Trava de segurança para evitar chamadas duplicadas
    if (_isLoading || _isLoadingMore || _isRefreshing) {
      return;
    }

    if (refresh) {
      _isRefreshing = true;
      // Mantém _rankings para evitar sumiço visual durante pull-to-refresh
      _nextCursor = null;
      _hasMore = true;
      _errorMessage = null;
    }

    // Proteção contra loop de paginação:
    // Se não for refresh (carregar mais), já tivermos itens, mas não tivermos cursor,
    // não podemos carregar mais (evita buscar página 1 novamente).
    if (!refresh && _rankings.isNotEmpty && _nextCursor == null) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    _isLoading = refresh;
    if (!refresh) _isLoadingMore = true;
    
    // [FIX] Notifica se a lista estiver vazia para mostrar o skeleton no carregamento inicial
    if (_rankings.isEmpty) {
      notifyListeners();
    }

    try {
      final response = await _loadLocalRankings();
      
      if (response.data != null) {
      }
      if (response.error != null) {
      }
      
      // Handle response
      if (response.success && response.data != null) {
        final data = response.data!;
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
        final List<dynamic> rankingsList = data['rankings'] ?? [];
        final newRankings = rankingsList
            .map((item) => RankingEntry.fromMap(item as Map<String, dynamic>))
            .toList();
            
        if (refresh) {
          _rankings = newRankings;
        } else {
          _rankings.addAll(newRankings);
        }
        
        // Paginação
        _nextCursor = data['nextCursor'];
        _hasMore = _nextCursor != null;
        _totalInRange = data['totalInRange'] ?? 0;
        
        // Atualiza cache
        _saveToCache();
      } else {
        _errorMessage = response.error?.message ?? 'Erro ao carregar ranking';
      }
    } catch (e) {
      _errorMessage = 'Erro de conexão';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> _loadLocalRankings() async {
    if (_userPosition == null) {
      return ApiResponse.failure(
        error: ApiError(
          code: 'no-location',
          message: 'Localização não disponível. Permita acesso à localização.',
        ),
      );
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
  
  void _loadFromCache(String key) {
    final cache = _cache[key]!;
    _currentUserRanking = cache.currentUserRanking;
    _rankings = List.from(cache.rankings);
    _nextCursor = cache.nextCursor;
    _hasMore = cache.hasMore;
    _totalInRange = cache.totalInRange;
    _errorMessage = null;
  }
  
  void _saveToCache() {
    final cache = _LocalRankingCache(
      currentUserRanking: _currentUserRanking,
      rankings: List.from(_rankings),
      nextCursor: _nextCursor,
      hasMore: _hasMore,
      totalInRange: _totalInRange,
      timestamp: DateTime.now(),
    );
    _cache[_selectedCategory] = cache;
  }
  
  /// Limpa todo o cache
  void clearCache() {
    _cache.clear();
  }
}

/// Cache para ranking local
class _LocalRankingCache {
  _LocalRankingCache({
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
