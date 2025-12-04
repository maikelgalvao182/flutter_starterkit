import 'dart:async';
import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/utils/geo_distance_helper.dart';
import 'package:partiu/features/home/data/models/event_model.dart';
import 'package:partiu/features/home/data/repositories/event_map_repository.dart';
import 'package:partiu/features/home/data/services/user_location_service.dart';
import 'package:partiu/features/home/presentation/services/event_marker_service.dart';
import 'package:partiu/services/location/location_query_service.dart';
import 'package:partiu/services/location/location_stream_controller.dart';
import 'package:partiu/shared/repositories/user_repository.dart';

/// ViewModel responsável por gerenciar o estado e lógica do mapa
/// 
/// Responsabilidades:
/// - Carregar eventos com filtro de raio
/// - Gerar markers
/// - Gerenciar estado dos markers
/// - Fornecer dados limpos para o widget
/// - Orquestrar serviços
/// - Reagir a mudanças de raio em tempo real
class AppleMapViewModel extends ChangeNotifier {
  final EventMapRepository _eventRepository;
  final UserLocationService _locationService;
  final EventMarkerService _markerService;
  final LocationQueryService _locationQueryService;
  final LocationStreamController _streamController;
  final UserRepository _userRepository;

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

  /// Callback quando um marker é tocado (recebe EventModel completo)
  Function(EventModel event)? onMarkerTap;

  /// Subscription para mudanças de raio
  StreamSubscription<double>? _radiusSubscription;

  /// Cache de nomes de criadores para evitar N+1 queries
  /// Key: userId, Value: fullName
  final Map<String, String?> _creatorNameCache = {};

  AppleMapViewModel({
    EventMapRepository? eventRepository,
    UserLocationService? locationService,
    EventMarkerService? markerService,
    LocationQueryService? locationQueryService,
    LocationStreamController? streamController,
    UserRepository? userRepository,
    this.onMarkerTap,
  })  : _eventRepository = eventRepository ?? EventMapRepository(),
        _locationService = locationService ?? UserLocationService(),
        _markerService = markerService ?? EventMarkerService(),
        _locationQueryService = locationQueryService ?? LocationQueryService(),
        _streamController = streamController ?? LocationStreamController(),
        _userRepository = userRepository ?? UserRepository() {
    _initializeRadiusListener();
  }

  /// Inicializa listener para mudanças de raio
  void _initializeRadiusListener() {
    _radiusSubscription = _streamController.radiusStream.listen((radiusKm) {
      debugPrint('🗺️ AppleMapViewModel: Raio atualizado para $radiusKm km');
      // Recarregar eventos com novo raio
      loadNearbyEvents();
    });
  }

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
  /// 2. Inicializa dados no Firestore se necessário
  /// 3. Busca eventos próximos (LocationQueryService - com filtros e bounding box)
  /// 4. Enriquece com distância e disponibilidade (_enrichEvents)
  /// 5. Gera markers
  /// 6. Atualiza estado
  Future<void> loadNearbyEvents() async {
    if (_isLoading) return;

    _setLoading(true);

    try {
      // 1. Obter localização
      final locationResult = await _locationService.getUserLocation();
      _lastLocation = locationResult.location;

      // 2. Inicializar dados do usuário no Firestore se necessário
      // Isso garante que os campos latitude, longitude e radiusKm existem
      await _locationQueryService.initializeUserLocation(
        latitude: _lastLocation!.latitude,
        longitude: _lastLocation!.longitude,
      );

      // 3. Buscar eventos (LocationQueryService - otimizado com bounding box)
      final eventsWithDistance = await _locationQueryService.getEventsWithinRadiusOnce();

      // 4. Converter para EventModel
      _events = eventsWithDistance.map((eventWithDistance) {
        return EventModel.fromMap(
          eventWithDistance.eventData,
          eventWithDistance.eventId,
        );
      }).toList();

      // 5. Enriquecer com distância e disponibilidade (lógica centralizada)
      await _enrichEvents();

      // 6. Gerar markers com callback de tap
      final markers = await _markerService.buildEventAnnotations(
        _events,
        onTap: onMarkerTap != null ? (eventId) {
          final event = _events.firstWhere((e) => e.id == eventId);
          onMarkerTap!(event);
        } : null,
      );
      _eventMarkers = markers;

      debugPrint('🗺️ AppleMapViewModel: ${_events.length} eventos carregados');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AppleMapViewModel: Erro ao carregar eventos: $e');
      // Erro será silencioso - markers continuam vazios
      _eventMarkers = {};
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Enriquece eventos com distância e disponibilidade ANTES de criar markers
  /// 
  /// IMPORTANTE: Esta é a ÚNICA fonte de verdade para calcular:
  /// - distanceKm: Distância do evento para o usuário
  /// - isAvailable: Se o usuário pode ver o evento (premium OU dentro de 30km)
  /// - creatorFullName: Nome completo do criador (se disponível)
  /// 
  /// Os repositórios (EventMapRepository, LocationQueryService) NÃO devem
  /// incluir esses campos - toda lógica de enriquecimento fica aqui no ViewModel
  Future<void> _enrichEvents() async {
    if (_lastLocation == null || _events.isEmpty) return;

    final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Buscar dados do usuário atual para verificar premium
    final currentUserDoc = await _userRepository.getUserById(currentUserId);
    final isPremium = currentUserDoc?['hasPremium'] as bool? ?? false;

    // Enriquecer cada evento
    _events = await Future.wait(_events.map((event) async {
      // 1. Calcular distância do evento para o usuário
      final distance = GeoDistanceHelper.distanceInKm(
        _lastLocation!.latitude,
        _lastLocation!.longitude,
        event.lat,
        event.lng,
      );

      // 2. Verificar disponibilidade usando regra de negócio
      final isAvailable = _canApplyToEvent(
        isPremium: isPremium,
        distanceKm: distance,
      );

      // 3. Buscar nome do criador (opcional, para enriquecer card) com cache
      String? creatorName;
      if (!_creatorNameCache.containsKey(event.createdBy)) {
        try {
          final creator = await _userRepository.getUserById(event.createdBy);
          _creatorNameCache[event.createdBy] = 
              creator?['fullName'] as String? ?? creator?['name'] as String?;
        } catch (e) {
          debugPrint('⚠️ Erro ao buscar criador do evento ${event.id}: $e');
          _creatorNameCache[event.createdBy] = null;
        }
      }
      creatorName = _creatorNameCache[event.createdBy];

      // 4. Retornar evento enriquecido
      return event.copyWith(
        distanceKm: distance,
        isAvailable: isAvailable,
        creatorFullName: creatorName,
      );
    }));

    debugPrint('✨ Enriquecidos ${_events.length} eventos com distância e disponibilidade');
  }

  /// Verifica se o usuário pode aplicar para um evento
  /// 
  /// Regra de negócio:
  /// - Usuários premium podem ver todos os eventos (ilimitado)
  /// - Usuários free podem ver apenas eventos dentro do limite configurado
  bool _canApplyToEvent({
    required bool isPremium,
    required double distanceKm,
  }) {
    return isPremium || distanceKm <= FREE_ACCOUNT_MAX_EVENT_DISTANCE_KM;
  }

  /// Atualiza eventos para uma localização específica
  /// 
  /// Útil quando o usuário move o mapa manualmente
  /// 
  /// DIFERENÇA de loadNearbyEvents():
  /// - Usa EventMapRepository (raio fixo, sem filtros avançados)
  /// - loadNearbyEvents() usa LocationQueryService (raio dinâmico, bounding box, filtros)
  /// 
  /// SEMELHANÇA:
  /// - Ambos chamam _enrichEvents() para calcular distância e disponibilidade
  Future<void> loadEventsAt(LatLng location) async {
    if (_isLoading) return;

    _setLoading(true);
    _lastLocation = location;

    try {
      // Buscar eventos (EventMapRepository - raio fixo)
      final events = await _eventRepository.getEventsWithinRadius(location);
      _events = events;

      // Enriquecer com distância e disponibilidade (lógica centralizada em _enrichEvents)
      await _enrichEvents();

      final markers = await _markerService.buildEventAnnotations(
        events,
        onTap: onMarkerTap != null ? (eventId) {
          final event = _events.firstWhere((e) => e.id == eventId);
          onMarkerTap!(event);
        } : null,
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
    _creatorNameCache.clear();
  }

  @override
  void dispose() {
    _radiusSubscription?.cancel();
    _markerService.clearCache();
    _creatorNameCache.clear();
    super.dispose();
  }
}
