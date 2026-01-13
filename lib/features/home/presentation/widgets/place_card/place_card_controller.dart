import 'package:flutter/foundation.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/features/home/data/repositories/event_repository.dart';
import 'package:partiu/features/home/data/repositories/event_application_repository.dart';

/// Controller para gerenciar dados do PlaceCard
class PlaceCardController extends ChangeNotifier {
  final EventRepository _eventRepo;
  final EventApplicationRepository _applicationRepo;
  final String eventId;
  final Map<String, dynamic>? _preloadedData; // Dados pré-carregados (opcional)

  String? _locationName;
  String? _formattedAddress;
  String? _placeId;
  List<String> _photoUrls = [];
  List<Map<String, dynamic>> _visitors = [];
  int _totalVisitorsCount = 0;
  bool _loaded = false;
  String? _error;

  PlaceCardController({
    required this.eventId,
    Map<String, dynamic>? preloadedData,
    EventRepository? eventRepo,
    EventApplicationRepository? applicationRepo,
  }) : _preloadedData = preloadedData,
       _eventRepo = eventRepo ?? EventRepository(),
       _applicationRepo = applicationRepo ?? EventApplicationRepository() {
    // Inicializar com dados pré-carregados se disponível
    if (_preloadedData != null) {
      _locationName = _preloadedData!['locationName'] as String?;
      _formattedAddress = _preloadedData!['formattedAddress'] as String?;
      _placeId = _preloadedData!['placeId'] as String?;
      
      final photoRefs = _preloadedData!['photoReferences'] as List<dynamic>?;
      if (photoRefs != null) {
        _photoUrls = photoRefs.map((e) => e.toString()).toList();
      }
      
      // Inicializar visitantes se disponível
      final visitors = _preloadedData!['visitors'] as List<Map<String, dynamic>>?;
      if (visitors != null) {
        _visitors = visitors;
      }
      
      final totalCount = _preloadedData!['totalVisitorsCount'] as int?;
      if (totalCount != null) {
        _totalVisitorsCount = totalCount;
      }
    }
  }

  // Getters
  String? get locationName => _locationName;
  String? get formattedAddress => _formattedAddress;
  String? get placeId => _placeId;
  List<String> get photoUrls => _photoUrls;
  List<Map<String, dynamic>> get visitors => _visitors;
  int get totalVisitorsCount => _totalVisitorsCount;
  bool get isLoading => !_loaded && _error == null && _preloadedData == null;
  String? get error => _error;
  bool get hasData => _error == null && _locationName != null;

  /// Carrega dados de localização do evento e visitantes
  Future<void> load() async {
    try {
      // Se já tem visitantes pré-carregados, não precisa buscar nada
      if (_preloadedData != null && _visitors.isNotEmpty) {
        _loaded = true;
        _error = null;
        notifyListeners();
        AppLogger.controller(
          'PlaceCardController: dados totalmente pré-carregados',
          tag: 'PLACE_CARD',
        );
        return;
      }
      
      // Se já tem dados pré-carregados de localização, apenas buscar visitantes
      if (_preloadedData != null) {
        // Carregar apenas visitantes em paralelo
        final results = await Future.wait([
          _applicationRepo.getRecentApplicationsWithUserData(eventId, limit: 3),
          _applicationRepo.getApprovedApplicationsCount(eventId),
        ]);

        _visitors = results[0] as List<Map<String, dynamic>>;
        _totalVisitorsCount = results[1] as int;

        AppLogger.controller(
          'PlaceCardController: ${_visitors.length} visitantes carregados, total: $_totalVisitorsCount',
          tag: 'PLACE_CARD',
        );
      } else {
        // Carregar tudo se não tiver dados pré-carregados
        final results = await Future.wait([
          _eventRepo.getEventLocationInfo(eventId),
          _applicationRepo.getRecentApplicationsWithUserData(eventId, limit: 3),
          _applicationRepo.getApprovedApplicationsCount(eventId),
        ]);

        final locationData = results[0] as Map<String, dynamic>?;
        _visitors = results[1] as List<Map<String, dynamic>>;
        _totalVisitorsCount = results[2] as int;

        if (locationData == null) {
          throw Exception('Localização não encontrada');
        }

        _locationName = locationData['locationName'] as String?;
        _formattedAddress = locationData['formattedAddress'] as String?;
        _placeId = locationData['placeId'] as String?;
        
        // Converter photoReferences para List<String>
        final photoRefs = locationData['photoReferences'] as List<dynamic>?;
        if (AppLogger.verbose) {
          AppLogger.controller(
            'PlaceCardController: photoReferences = $photoRefs',
            tag: 'PLACE_CARD',
          );
        }
        
        if (photoRefs != null) {
          _photoUrls = photoRefs.map((e) => e.toString()).toList();
          if (AppLogger.verbose) {
            AppLogger.controller(
              'PlaceCardController: _photoUrls convertidas = $_photoUrls',
              tag: 'PLACE_CARD',
            );
          }
        } else {
          AppLogger.warning(
            'PlaceCardController: photoReferences é null',
            tag: 'PLACE_CARD',
          );
        }

        AppLogger.controller(
          'PlaceCardController: ${_visitors.length} visitantes carregados, total: $_totalVisitorsCount',
          tag: 'PLACE_CARD',
        );
      }

      _loaded = true;
      _error = null;
      notifyListeners();
    } catch (e, stackTrace) {
      _error = 'Erro ao carregar localização: $e';
      _loaded = true;
      AppLogger.error(
        'PlaceCardController: $_error',
        tag: 'PLACE_CARD',
        error: e,
        stackTrace: stackTrace,
      );
      notifyListeners();
    }
  }

  /// Recarrega os dados
  Future<void> refresh() async {
    _loaded = false;
    _error = null;
    notifyListeners();
    await load();
  }
}
