import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/data/models/location_filter.dart';
import 'package:partiu/features/home/data/models/locations_ranking_model.dart';

/// State holder para ranking de lugares
/// 
/// Segue o mesmo padrão do PeopleRankingState:
/// - Lista master imutável (nunca muda)
/// - Filtro local reativo
/// - Zero requery, zero streams
/// - Filtragem instantânea
class LocationRankingState extends ChangeNotifier {
  /// Lista master — nunca muda, nunca perde dados
  final List<LocationRankingModel> master;

  /// Filtro ativo
  LocationFilter filter = const LocationFilter();

  LocationRankingState(this.master);

  // ---------------------------------------------
  // Métodos para mudar filtros
  // ---------------------------------------------
  
  /// Atualiza filtro de estado e reseta cidade
  void setStateFilter(String? state) {
    filter = LocationFilter(state: state, city: null);
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
    filter = const LocationFilter();
    _resetPagination();
    notifyListeners();
  }
  
  /// Atualiza lista master (quando ViewModel recarrega)
  void updateMaster(List<LocationRankingModel> newMaster) {
    (master as List<LocationRankingModel>).clear();
    (master as List<LocationRankingModel>).addAll(newMaster);
    _resetPagination();
    notifyListeners();
  }

  // ---------------------------------------------
  // Lista filtrada reativa
  // ---------------------------------------------
  
  /// Retorna lista filtrada baseado no filtro atual
  List<LocationRankingModel> get filteredItems {
    var list = master;

    // Filtrar por estado
    if (filter.state != null && filter.state!.isNotEmpty) {
      list = list.where((loc) => loc.state == filter.state).toList();
    }

    // Filtrar por cidade
    if (filter.city != null && filter.city!.isNotEmpty) {
      list = list.where((loc) => loc.locality == filter.city).toList();
    }

    return list;
  }

  /// IDs dos items visíveis (para usar com Visibility)
  Set<String> get visibleIds {
    return filteredItems.map((e) => e.placeId).toSet();
  }
  
  // ---------------------------------------------
  // 🚀 Paginação local (para InfiniteListView)
  // ---------------------------------------------
  
  int _displayedCount = 30;
  
  /// Rankings exibidos (paginados)
  List<LocationRankingModel> get displayedRankings {
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
    
    debugPrint('📄 [LocationRankingState] LoadMore: $_displayedCount -> $newCount');
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
        .map((loc) => loc.state)
        .where((e) => e != null && e.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList()
      ..sort();
  }

  /// Cidades disponíveis na lista filtrada por estado (se selecionado)
  List<String> get availableCities {
    var list = master;
    
    // Se tem estado selecionado, filtrar apenas cidades daquele estado
    if (filter.state != null && filter.state!.isNotEmpty) {
      list = list.where((loc) => loc.state == filter.state).toList();
    }
    
    return list
        .map((loc) => loc.locality)
        .where((e) => e != null && e.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList()
      ..sort();
  }
}
