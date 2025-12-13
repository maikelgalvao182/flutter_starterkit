import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/data/models/location_filter.dart';
import 'package:partiu/features/home/data/models/locations_ranking_model.dart';

/// State holder para ranking de lugares
/// 
/// Segue o mesmo padrão do PeopleRankingState:
/// - Lista master imutável (fonte de verdade)
/// - Filtro local reativo
/// - Zero requery, zero streams
/// - Filtragem instantânea
/// - 🔥 BLINDAGEM: preserva dados durante refresh
class LocationRankingState extends ChangeNotifier {
  /// Lista master — FONTE DE VERDADE (nunca limpa durante refresh)
  final List<LocationRankingModel> master;

  /// Filtro ativo
  LocationFilter filter = const LocationFilter();
  
  /// 🛡️ BLINDAGEM: dados anteriores para manter UI estável durante refresh
  List<LocationRankingModel> _previousDisplayedRankings = [];
  Set<String> _previousVisibleIds = {};
  List<String> _previousStates = [];
  List<String> _previousCities = [];
  
  /// 🔒 Flag para detectar se estamos em refresh (proteção contra limpeza)
  bool _isRefreshing = false;

  LocationRankingState(this.master) {
    // Inicializar dados anteriores
    _updatePreviousData();
  }

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
  
  /// Atualiza lista master de forma SEGURA (nunca limpa durante refresh)
  /// 🔥 REGRA DE OURO: Durante refresh, NENHUM estado derivado pode ser resetado
  void updateMaster(List<LocationRankingModel> newMaster, {bool isRefreshing = false}) {
    debugPrint('🔄 [LocationRankingState] updateMaster called');
    debugPrint('   - newMaster.length: ${newMaster.length}');
    debugPrint('   - isRefreshing: $isRefreshing');
    debugPrint('   - current master.length: ${master.length}');
    
    // 🛡️ BLINDAGEM: Proteger contra limpeza indevida durante refresh
    if (isRefreshing && master.isNotEmpty) {
      debugPrint('   🛡️ BLINDAGEM ATIVA - preservando dados durante refresh');
      _isRefreshing = true;
      
      // Salvar estado atual ANTES de qualquer mudança
      _updatePreviousData();
    }
    
    // 🔥 CORREÇÃO CIRÚRGICA: Usar replaceRange ao invés de clear() + addAll()
    if (master.length != newMaster.length) {
      master.clear();
      master.addAll(newMaster);
    } else {
      // Se mesmo tamanho, substitua item por item (mais suave)
      for (int i = 0; i < newMaster.length; i++) {
        master[i] = newMaster[i];
      }
    }
    
    debugPrint('   - APÓS UPDATE master.length: ${master.length}');
    
    // Resetar paginação apenas se não estiver em refresh
    if (!isRefreshing) {
      _resetPagination();
    }
    
    notifyListeners();
    
    // Limpar flag de refresh após notificar
    if (isRefreshing) {
      _isRefreshing = false;
    }
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

  /// IDs dos items visíveis (para usar com Visibility) com BLINDAGEM
  Set<String> get visibleIds {
    final current = filteredItems.map((e) => e.placeId).toSet();
    
    // 🛡️ BLINDAGEM: Durante refresh, usar dados anteriores se conjunto atual estiver vazio
    if (_isRefreshing && current.isEmpty && _previousVisibleIds.isNotEmpty) {
      debugPrint('🛡️ [visibleIds] BLINDAGEM ATIVA - usando dados anteriores durante refresh');
      return _previousVisibleIds;
    }
    
    return current;
  }
  
  // ---------------------------------------------
  // 🚀 Paginação local (para InfiniteListView)
  // ---------------------------------------------
  
  int _displayedCount = 30;
  
  /// Rankings exibidos (paginados) com BLINDAGEM durante refresh
  List<LocationRankingModel> get displayedRankings {
    // 🛡️ BLINDAGEM: Durante refresh, usar dados anteriores se lista atual estiver vazia
    final filtered = filteredItems;
    final current = filtered.take(_displayedCount).toList();
    
    // 🔥 PROTEÇÃO: Nunca retornar lista vazia durante refresh se havia dados antes
    if (_isRefreshing && current.isEmpty && _previousDisplayedRankings.isNotEmpty) {
      debugPrint('🛡️ [displayedRankings] BLINDAGEM ATIVA - usando dados anteriores durante refresh');
      return _previousDisplayedRankings;
    }
    
    return current;
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
  
  /// 🛡️ Atualiza dados anteriores para blindagem durante refresh
  void _updatePreviousData() {
    if (!_isRefreshing) { // Evita recursão
      _previousDisplayedRankings = List.from(filteredItems.take(_displayedCount));
      _previousVisibleIds = Set.from(filteredItems.map((e) => e.placeId));
      _previousStates = List.from(_getStatesFromMaster());
      _previousCities = List.from(_getCitiesFromMaster());
      debugPrint('🛡️ [LocationRankingState] Dados anteriores atualizados para blindagem');
    }
  }

  // ---------------------------------------------
  // Opções únicas do filtro com BLINDAGEM
  // ---------------------------------------------
  
  /// Estados disponíveis na lista master com BLINDAGEM
  List<String> get availableStates {
    final current = _getStatesFromMaster();
    
    // 🛡️ BLINDAGEM: Durante refresh, usar dados anteriores se lista atual estiver vazia
    if (_isRefreshing && current.isEmpty && _previousStates.isNotEmpty) {
      debugPrint('🛡️ [availableStates] BLINDAGEM ATIVA - usando dados anteriores durante refresh');
      return _previousStates;
    }
    
    return current;
  }

  /// Cidades disponíveis baseado no estado selecionado com BLINDAGEM
  List<String> get availableCities {
    final current = _getCitiesFromMaster();
    
    // 🛡️ BLINDAGEM: Durante refresh, usar dados anteriores se lista atual estiver vazia
    if (_isRefreshing && current.isEmpty && _previousCities.isNotEmpty) {
      debugPrint('🛡️ [availableCities] BLINDAGEM ATIVA - usando dados anteriores durante refresh');
      return _previousCities;
    }
    
    return current;
  }
  
  /// Helper para extrair estados da master list
  List<String> _getStatesFromMaster() {
    return master
        .map((loc) => loc.state)
        .where((e) => e != null && e.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList()
      ..sort();
  }
  
  /// Helper para extrair cidades da master list
  List<String> _getCitiesFromMaster() {
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
