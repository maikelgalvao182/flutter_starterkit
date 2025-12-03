import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/data/models/event_model.dart';
import 'package:partiu/features/home/data/repositories/event_map_repository.dart';
import 'package:partiu/features/home/data/services/user_location_service.dart';
import 'package:partiu/features/home/presentation/services/event_marker_service.dart';

/// ViewModel responsável por gerenciar o estado e lógica do mapa
/// 
/// Responsabilidades:
/// - Carregar eventos
/// - Gerar markers
/// - Gerenciar estado dos markers
/// - Fornecer dados limpos para o widget
/// - Orquestrar serviços
class AppleMapViewModel extends ChangeNotifier {
  final EventMapRepository _eventRepository;
  final UserLocationService _locationService;
  final EventMarkerService _markerService;

  /// Markers atualmente exibidos no mapa
  Set<Annotation> _eventMarkers = {};
  Set<Annotation> get eventMarkers => _eventMarkers;

  /// Estado de carregamento
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Última localização obtida
  LatLng? _lastLocation;
  LatLng? get lastLocation => _lastLocation;

  /// Eventos carregados
  List<EventModel> _events = [];
  List<EventModel> get events => _events;

  /// Callback quando um marker é tocado
  Function(String eventId)? onMarkerTap;

  AppleMapViewModel({
    EventMapRepository? eventRepository,
    UserLocationService? locationService,
    EventMarkerService? markerService,
    this.onMarkerTap,
  })  : _eventRepository = eventRepository ?? EventMapRepository(),
        _locationService = locationService ?? UserLocationService(),
        _markerService = markerService ?? EventMarkerService();

  /// Inicializa o ViewModel
  /// 
  /// Deve ser chamado após o mapa estar pronto
  Future<void> initialize() async {
    await _markerService.preloadDefaultPins();
  }

  /// Carrega eventos próximos à localização do usuário
  /// 
  /// Este método:
  /// 1. Obtém localização do usuário
  /// 2. Busca eventos próximos
  /// 3. Gera markers
  /// 4. Atualiza estado
  Future<void> loadNearbyEvents() async {
    if (_isLoading) return;

    _setLoading(true);

    try {
      // 1. Obter localização
      final location = await _locationService.getLocationOrDefault();
      _lastLocation = location;

      // 2. Buscar eventos
      final events = await _eventRepository.getEventsWithinRadius(location);
      _events = events;

      // 3. Gerar markers com callback de tap
      final markers = await _markerService.buildEventAnnotations(
        events,
        onTap: onMarkerTap,
      );
      _eventMarkers = markers;

      notifyListeners();
    } catch (e) {
      // Erro será silencioso - markers continuam vazios
      _eventMarkers = {};
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza eventos para uma localização específica
  /// 
  /// Útil quando o usuário move o mapa manualmente
  Future<void> loadEventsAt(LatLng location) async {
    if (_isLoading) return;

    _setLoading(true);
    _lastLocation = location;

    try {
      final events = await _eventRepository.getEventsWithinRadius(location);
      _events = events;

      final markers = await _markerService.buildEventAnnotations(
        events,
        onTap: onMarkerTap,
      );
      _eventMarkers = markers;

      notifyListeners();
    } catch (e) {
      _eventMarkers = {};
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Recarrega eventos (força atualização)
  Future<void> refresh() async {
    if (_lastLocation != null) {
      await loadEventsAt(_lastLocation!);
    } else {
      await loadNearbyEvents();
    }
  }

  /// Limpa todos os markers
  void clearMarkers() {
    _eventMarkers = {};
    _events = [];
    notifyListeners();
  }

  /// Obtém localização do usuário
  /// 
  /// Retorna LocationResult com informações detalhadas
  Future<LocationResult> getUserLocation() async {
    return await _locationService.getUserLocation();
  }

  /// Define estado de carregamento
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Limpa cache de markers
  void clearCache() {
    _markerService.clearCache();
  }

  @override
  void dispose() {
    _markerService.clearCache();
    super.dispose();
  }
}
