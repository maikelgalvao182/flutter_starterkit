import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/data/models/user_ranking_model.dart';
import 'package:partiu/features/home/data/services/people_ranking_service.dart';

/// ViewModel para gerenciar estado do ranking de pessoas
/// 
/// Responsabilidades:
/// - Carregar ranking de pessoas baseado em reviews
/// - Gerenciar estado de loading e erros
/// - Filtrar por cidade
/// - Fornecer dados limpos para a UI
class PeopleRankingViewModel extends ChangeNotifier {
  final PeopleRankingService _peopleRankingService;

  // Estado
  bool _isLoading = true; // Começa como true para mostrar shimmer imediatamente
  String? _error;

  // Dados
  List<UserRankingModel> _peopleRankings = [];
  List<String> _availableCities = [];

  // Filtros
  String? _selectedCity;

  PeopleRankingViewModel({
    PeopleRankingService? peopleRankingService,
  }) : _peopleRankingService = peopleRankingService ?? PeopleRankingService();

  // Getters - Estado
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters - Dados
  List<UserRankingModel> get peopleRankings => _peopleRankings;
  List<String> get availableCities => _availableCities;

  // Getters - Filtros
  String? get selectedCity => _selectedCity;

  /// Inicializa o ViewModel carregando rankings e cidades
  Future<void> initialize() async {
    debugPrint('🚀 [PeopleRankingViewModel] Inicializando...');
    await Future.wait([
      loadPeopleRanking(),
      _loadAvailableCities(),
    ]);
    debugPrint('✅ [PeopleRankingViewModel] Inicialização completa');
  }

  /// Carrega ranking de pessoas
  Future<void> loadPeopleRanking() async {
    debugPrint('📊 [PeopleRankingViewModel] Iniciando loadPeopleRanking');
    debugPrint('   - selectedCity: $_selectedCity');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('   - Chamando service.getPeopleRanking...');
      _peopleRankings = await _peopleRankingService.getPeopleRanking(
        selectedLocality: _selectedCity,
        limit: 50,
      );
      debugPrint('✅ Ranking de pessoas carregado: ${_peopleRankings.length} pessoas');
      
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

  /// Carrega lista de cidades disponíveis
  Future<void> _loadAvailableCities() async {
    debugPrint('🌆 [PeopleRankingViewModel] Carregando cidades...');
    try {
      _availableCities = await _peopleRankingService.getAvailableCities();
      debugPrint('✅ Cidades disponíveis: ${_availableCities.length}');
      if (_availableCities.isNotEmpty) {
        debugPrint('   - Primeiras 5: ${_availableCities.take(5).join(", ")}');
      }
    } catch (error, stackTrace) {
      debugPrint('⚠️ Erro ao carregar cidades: $error');
      debugPrint('   StackTrace: $stackTrace');
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

  /// Limpa filtro de cidade
  Future<void> clearCityFilter() async {
    await selectCity(null);
  }

  /// Recarrega ranking
  Future<void> refresh() async {
    await initialize();
  }
}
