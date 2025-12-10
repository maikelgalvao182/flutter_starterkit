import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/data/models/user_ranking_model.dart';
import 'package:partiu/features/home/data/services/people_ranking_service.dart';
import 'package:partiu/core/services/block_service.dart';
import 'package:partiu/common/state/app_state.dart';

/// ViewModel para gerenciar estado do ranking de pessoas
/// 
/// Responsabilidades:
/// - Carregar ranking de pessoas baseado em reviews
/// - Gerenciar estado de loading e erros
/// - Filtrar por cidade
/// - Fornecer dados limpos para a UI
class PeopleRankingViewModel extends ChangeNotifier {
  final PeopleRankingService _peopleRankingService;
  
  // Instância compartilhada (opcional - para acesso global)
  static PeopleRankingViewModel? _instance;
  static PeopleRankingViewModel? get instance => _instance;
  static set instance(PeopleRankingViewModel? value) => _instance = value;

  // Estado
  bool _isLoading = true; // Começa como true para mostrar shimmer imediatamente
  String? _error;

  // Dados
  List<UserRankingModel> _peopleRankings = [];
  List<String> _availableStates = [];
  List<String> _availableCities = [];
  
  // Cache de cidades por estado para não reprocessar
  Map<String, List<String>> _citiesByState = {};

  // Filtros
  String? _selectedState;
  String? _selectedCity;

  PeopleRankingViewModel({
    PeopleRankingService? peopleRankingService,
  }) : _peopleRankingService = peopleRankingService ?? PeopleRankingService();

  // Getters - Estado
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters - Dados
  List<UserRankingModel> get peopleRankings => _peopleRankings;
  List<String> get availableStates => _availableStates;
  List<String> get availableCities => _availableCities;

  // Getters - Filtros
  String? get selectedState => _selectedState;
  String? get selectedCity => _selectedCity;

  /// Inicializa o ViewModel carregando rankings e filtros disponíveis
  Future<void> initialize() async {
    debugPrint('🚀 [PeopleRankingViewModel] Inicializando...');
    
    // ⬅️ ESCUTA BlockService via ChangeNotifier (REATIVO INSTANTÂNEO)
    BlockService.instance.addListener(_onBlockedUsersChanged);
    
    await Future.wait([
      loadPeopleRanking(),
      _loadAvailableStates(),
      _loadAvailableCities(),
    ]);
    debugPrint('✅ [PeopleRankingViewModel] Inicialização completa');
  }
  
  /// Callback quando BlockService muda (via ChangeNotifier)
  void _onBlockedUsersChanged() {
    debugPrint('🔄 Bloqueios mudaram - refiltrando ranking de pessoas...');
    _refilterPeopleRanking();
  }
  
  /// Re-filtra ranking removendo usuários bloqueados
  void _refilterPeopleRanking() {
    final currentUserId = AppState.currentUserId;
    if (currentUserId == null) return;
    
    final beforeCount = _peopleRankings.length;
    final blockedIds = BlockService.instance.getAllBlockedIds(currentUserId);
    
    _peopleRankings = _peopleRankings
        .where((person) => !blockedIds.contains(person.userId))
        .toList();
    
    final afterCount = _peopleRankings.length;
    final removedCount = beforeCount - afterCount;
    
    if (removedCount > 0) {
      debugPrint('🚫 [PeopleRankingViewModel] $removedCount pessoas removidas do ranking');
      notifyListeners();
    }
  }

  /// Carrega ranking de pessoas
  Future<void> loadPeopleRanking() async {
    debugPrint('📊 [PeopleRankingViewModel] Iniciando loadPeopleRanking');
    debugPrint('   - selectedState: $_selectedState');
    debugPrint('   - selectedCity: $_selectedCity');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('   - Chamando service.getPeopleRanking...');
      _peopleRankings = await _peopleRankingService.getPeopleRanking(
        selectedState: _selectedState,
        selectedLocality: _selectedCity,
        limit: 50,
      );
      debugPrint('✅ Ranking de pessoas carregado: ${_peopleRankings.length} pessoas');
      
      // Filtra usuários bloqueados imediatamente
      final currentUserId = AppState.currentUserId;
      if (currentUserId != null) {
        final blockedIds = BlockService.instance.getAllBlockedIds(currentUserId);
        final beforeFilter = _peopleRankings.length;
        _peopleRankings = _peopleRankings
            .where((person) => !blockedIds.contains(person.userId))
            .toList();
        final afterFilter = _peopleRankings.length;
        if (beforeFilter != afterFilter) {
          debugPrint('🚫 ${beforeFilter - afterFilter} pessoas bloqueadas filtradas');
        }
      }
      
      if (_peopleRankings.isNotEmpty) {
        debugPrint('   - Top 3:');
        for (var i = 0; i < _peopleRankings.length && i < 3; i++) {
          final r = _peopleRankings[i];
          debugPrint('     ${i + 1}. ${r.fullName} - ${r.overallRating}⭐ (${r.totalReviews} reviews)');
        }
      }
    } catch (error, stackTrace) {
      _error = 'Erro ao carregar ranking de pessoas';
      debugPrint('❌ [PeopleRankingViewModel] $_error');
      debugPrint('   Error: $error');
      debugPrint('   StackTrace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('   - isLoading: $_isLoading');
      debugPrint('   - error: $_error');
    }
  }

  /// Carrega lista de estados disponíveis
  Future<void> _loadAvailableStates() async {
    debugPrint('🗺️ [PeopleRankingViewModel] Carregando estados...');
    try {
      _availableStates = await _peopleRankingService.getAvailableStates();
      debugPrint('✅ Estados disponíveis: ${_availableStates.length}');
      if (_availableStates.isNotEmpty) {
        debugPrint('   - Estados: ${_availableStates.join(", ")}');
      }
    } catch (error, stackTrace) {
      debugPrint('⚠️ Erro ao carregar estados: $error');
      debugPrint('   StackTrace: $stackTrace');
    }
  }

  /// Carrega lista de cidades disponíveis
  Future<void> _loadAvailableCities() async {
    debugPrint('🌆 [PeopleRankingViewModel] Carregando cidades...');
    try {
      final allCities = await _peopleRankingService.getAvailableCities();
      debugPrint('✅ Cidades totais disponíveis: ${allCities.length}');
      
      // Inicialmente, carregar todas as cidades
      _availableCities = allCities;
      
      if (_availableCities.isNotEmpty) {
        debugPrint('   - Primeiras 5: ${_availableCities.take(5).join(", ")}');
      }
    } catch (error, stackTrace) {
      debugPrint('⚠️ Erro ao carregar cidades: $error');
      debugPrint('   StackTrace: $stackTrace');
    }
  }

  /// Atualiza filtro de estado
  Future<void> selectState(String? state) async {
    if (_selectedState == state) {
      debugPrint('🗺️ [PeopleRankingViewModel] Estado já selecionado: $state');
      return;
    }
    
    _selectedState = state;
    _selectedCity = null; // Reset cidade ao trocar estado
    
    debugPrint('🗺️ [PeopleRankingViewModel] Estado selecionado: ${state ?? "Todos"}');
    
    // Atualizar lista de cidades baseado no estado
    await _updateAvailableCitiesForState();
    
    notifyListeners();
    await loadPeopleRanking();
  }

  /// Atualiza lista de cidades baseado no estado selecionado
  Future<void> _updateAvailableCitiesForState() async {
    if (_selectedState == null) {
      // Se nenhum estado selecionado, mostrar todas as cidades
      _availableCities = await _peopleRankingService.getAvailableCities();
      return;
    }
    
    // Verificar cache
    if (_citiesByState.containsKey(_selectedState)) {
      _availableCities = _citiesByState[_selectedState]!;
      debugPrint('   📦 Usando cache: ${_availableCities.length} cidades');
      return;
    }
    
    // Buscar cidades do estado selecionado filtrando do ranking
    debugPrint('   🔍 Filtrando cidades do estado: $_selectedState');
    try {
      // Buscar rankings do estado para extrair cidades
      final stateRankings = await _peopleRankingService.getPeopleRanking(
        selectedState: _selectedState,
        limit: 1000, // Buscar bastante para pegar todas as cidades
      );
      
      final cities = stateRankings
          .map((r) => r.locality)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      
      _availableCities = cities;
      _citiesByState[_selectedState!] = cities; // Cachear
      
      debugPrint('   ✅ ${_availableCities.length} cidades no estado $_selectedState');
    } catch (error) {
      debugPrint('   ⚠️ Erro ao filtrar cidades: $error');
      _availableCities = [];
    }
  }

  /// Atualiza filtro de cidade
  Future<void> selectCity(String? city) async {
    if (_selectedCity == city) {
      debugPrint('🌆 [PeopleRankingViewModel] Cidade já selecionada: $city');
      return;
    }
    
    _selectedCity = city;
    debugPrint('🌆 [PeopleRankingViewModel] Cidade selecionada: ${city ?? "Todas"}');
    
    notifyListeners();
    await loadPeopleRanking();
  }

  /// Limpa filtro de estado
  Future<void> clearStateFilter() async {
    await selectState(null);
  }

  /// Limpa filtro de cidade
  Future<void> clearCityFilter() async {
    await selectCity(null);
  }

  /// Recarrega ranking
  Future<void> refresh() async {
    await initialize();
  }
  
  @override
  void dispose() {
    BlockService.instance.removeListener(_onBlockedUsersChanged);
    super.dispose();
  }
}
