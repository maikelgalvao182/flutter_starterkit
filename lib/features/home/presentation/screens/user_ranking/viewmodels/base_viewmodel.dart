import 'package:flutter/foundation.dart';
import 'package:dating_app/screens/ranking/models/ranking_entry.dart';

abstract class BaseRankingViewModel extends ChangeNotifier {
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

  // Cache: category => data
  final Map<String, _RankingCache> _cache = {};

  // GETTERS PÚBLICOS
  List<RankingEntry> get rankings => List.unmodifiable(_rankings);
  RankingEntry? get currentUserRanking => _currentUserRanking;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  int get totalInRange => _totalInRange;

  /// Deve ser implementado pela classe filha
  Future<Map<String, dynamic>> loadData({
    required String? cursor,
    required String? category,
  });

  /// Inicialização depende da filha
  Future<void> initialize();

  /// Troca categoria
  Future<void> changeCategory(String category) async {
    if (_selectedCategory == category) return;

    _selectedCategory = category;
    _rankings = [];
    _currentUserRanking = null;
    _nextCursor = null;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();

    // usa cache se recente
    if (_cache.containsKey(category)) {
      final cache = _cache[category]!;
      if (DateTime.now().difference(cache.timestamp).inMinutes < 30) {
        _loadFromCache(category);
        notifyListeners();
        return;
      }
    }

    await loadRankings(refresh: true);
  }

  /// Lógica central para carregar ranking
  Future<void> loadRankings({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore || _isRefreshing) return;

    if (refresh) {
      _isRefreshing = true;
      _rankings = [];
      _nextCursor = null;
      _hasMore = true;
      _errorMessage = null;
    }

    if (!refresh && _rankings.isNotEmpty && _nextCursor == null) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    _isLoading = refresh;
    if (!refresh) _isLoadingMore = true;

    if (_rankings.isEmpty) notifyListeners();

    try {
      final data = await loadData(
        cursor: _nextCursor,
        category: _selectedCategory != 'All' ? _selectedCategory : null,
      );

      // CURRENT USER
      _currentUserRanking = data['currentUserRanking'] != null
          ? RankingEntry.fromMap(data['currentUserRanking'], isCurrentUser: true)
          : null;

      // LISTA
      final newRankings = (data['rankings'] as List<dynamic>)
          .map((e) => RankingEntry.fromMap(e))
          .toList();

      if (refresh) _rankings = newRankings;
      else _rankings.addAll(newRankings);

      // PAGINAÇÃO
      _nextCursor = data['nextCursor'];
      _hasMore = _nextCursor != null;
      _totalInRange = data['totalInRange'] ?? 0;

      // SAVE CACHE
      _saveToCache();

    } catch (e) {
      _errorMessage = 'Erro ao carregar ranking.';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void _loadFromCache(String key) {
    final c = _cache[key]!;
    _rankings = List.from(c.rankings);
    _currentUserRanking = c.currentUserRanking;
    _nextCursor = c.nextCursor;
    _hasMore = c.hasMore;
    _totalInRange = c.totalInRange;
    _errorMessage = null;
  }

  void _saveToCache() {
    _cache[_selectedCategory] = _RankingCache(
      rankings: List.from(_rankings),
      currentUserRanking: _currentUserRanking,
      nextCursor: _nextCursor,
      hasMore: _hasMore,
      totalInRange: _totalInRange,
      timestamp: DateTime.now(),
    );
  }

  void clearCache() => _cache.clear();
}

/// Cache genérico
class _RankingCache {
  _RankingCache({
    required this.rankings,
    required this.currentUserRanking,
    required this.nextCursor,
    required this.hasMore,
    required this.totalInRange,
    required this.timestamp,
  });

  final List<RankingEntry> rankings;
  final RankingEntry? currentUserRanking;
  final String? nextCursor;
  final bool hasMore;
  final int totalInRange;
  final DateTime timestamp;
}
