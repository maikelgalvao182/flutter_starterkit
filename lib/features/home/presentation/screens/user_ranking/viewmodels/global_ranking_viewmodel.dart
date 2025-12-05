import 'package:dating_app/api/ranking_api_rest.dart';
import 'package:dating_app/screens/ranking/models/ranking_entry.dart';
import 'package:flutter/foundation.dart';

/// ViewModel específico para Ranking Global
/// 
/// Responsabilidades:
/// - Gerenciar estado do ranking global da plataforma
/// - Cache isolado para não interferir com ranking local
/// - Paginação e filtros por categoria
class GlobalRankingViewModel extends ChangeNotifier {
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
  
  // Cache global isolado
  final Map<String, _GlobalRankingCache> _cache = {};
  
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
  
  /// Inicializa ranking global
  Future<void> initialize() async {
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
  
  /// Carrega rankings globais
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
      final response = await _api.getRankingGlobal(
        category: _selectedCategory != 'All' ? _selectedCategory : null,
        limit: 10,
        cursor: _nextCursor,
      );

      if (response.data != null) {
      }
      if (response.error != null) {
      }

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
    final cache = _GlobalRankingCache(
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

/// Cache para ranking global
class _GlobalRankingCache {
  _GlobalRankingCache({
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
