import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/data/models/people_filter.dart';
import 'package:partiu/features/home/data/models/user_ranking_model.dart';

/// State holder para ranking de pessoas
/// 
/// Segue o mesmo padrão do WeddingDiscoveryState:
/// - Lista master imutável (nunca muda)
/// - Filtro local reativo
/// - Zero requery, zero streams
/// - Filtragem instantânea
class PeopleRankingState extends ChangeNotifier {
  /// Lista master — nunca muda, nunca perde dados
  final List<UserRankingModel> master;

  /// Filtro ativo
  PeopleFilter filter = const PeopleFilter();

  PeopleRankingState(this.master);

  // ---------------------------------------------
  // Métodos para mudar filtros
  // ---------------------------------------------
  
  /// Atualiza filtro de estado e reseta cidade
  void setStateFilter(String? state) {
    filter = PeopleFilter(state: state, city: null);
    _resetPagination();
    notifyListeners();
  }

  /// Atualiza filtro de cidade
  void setCityFilter(String? city) {
    filter = filter.copyWith(city: city);
    _resetPagination();
    notifyListeners();
  }

  /// Limpa todos os filtros
  void clearFilters() {
    filter = const PeopleFilter();
    _resetPagination();
    notifyListeners();
  }
  
  /// Atualiza lista master (quando ViewModel recarrega)
  void updateMaster(List<UserRankingModel> newMaster) {
    (master as List<UserRankingModel>).clear();
    (master as List<UserRankingModel>).addAll(newMaster);
    _resetPagination();
    notifyListeners();
  }

  // ---------------------------------------------
  // Lista filtrada reativa
  // ---------------------------------------------
  
  /// Retorna lista filtrada baseado no filtro atual
  List<UserRankingModel> get filteredItems {
    var list = master;

    // Filtro por estado
    if (filter.state != null && filter.state!.isNotEmpty) {
      list = list.where((u) => u.state == filter.state).toList();
    }

    // Filtro por cidade
    if (filter.city != null && filter.city!.isNotEmpty) {
      list = list.where((u) => u.locality == filter.city).toList();
    }

    return list;
  }

  /// IDs dos items visíveis (para usar com Visibility)
  Set<String> get visibleIds {
    return filteredItems.map((e) => e.userId).toSet();
  }
  
  // ---------------------------------------------
  // 🚀 Paginação local (para InfiniteListView)
  // ---------------------------------------------
  
  int _displayedCount = 30;
  
  /// Rankings exibidos (paginados)
  List<UserRankingModel> get displayedRankings {
    final filtered = filteredItems;
    return filtered.take(_displayedCount).toList();
  }
  
  /// Se tem mais rankings para carregar
  bool get hasMore => _displayedCount < filteredItems.length;
  
  /// Carrega mais rankings (paginação local - dados já em memória)
  void loadMore() {
    if (!hasMore) return;
    
    final filtered = filteredItems;
    final newCount = (_displayedCount + 30).clamp(0, filtered.length);
    
    debugPrint('📄 [PeopleRankingState] LoadMore: $_displayedCount -> $newCount');
    _displayedCount = newCount;
    notifyListeners();
  }
  
  /// Reset paginação (chamado ao mudar filtros)
  void _resetPagination() {
    _displayedCount = 30;
  }

  // ---------------------------------------------
  // Opções únicas do filtro
  // ---------------------------------------------
  
  /// Estados disponíveis na lista master
  List<String> get availableStates {
    return master
        .map((u) => u.state)
        .where((e) => e != null && e.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList()
      ..sort();
  }

  /// Cidades disponíveis baseado no estado selecionado
  List<String> get availableCities {
    // Se nenhum estado selecionado, mostrar todas as cidades
    if (filter.state == null || filter.state!.isEmpty) {
      return master
          .map((u) => u.locality)
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    }

    // Se estado selecionado, mostrar apenas cidades daquele estado
    return master
        .where((u) => u.state == filter.state)
        .map((u) => u.locality)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }
}
