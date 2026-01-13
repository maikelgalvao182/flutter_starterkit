import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partiu/core/models/user.dart' as app_user;
import 'package:partiu/core/services/block_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:partiu/core/services/toast_service.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/features/home/data/models/event_model.dart';
import 'package:partiu/features/home/data/models/map_bounds.dart';
import 'package:partiu/features/home/data/services/map_discovery_service.dart';
import 'package:partiu/features/home/data/services/people_map_discovery_service.dart';
import 'package:partiu/features/home/presentation/services/google_event_marker_service.dart';
import 'package:partiu/features/home/presentation/services/map_navigation_service.dart';
import 'package:partiu/features/home/presentation/services/onboarding_service.dart';
import 'package:partiu/features/home/presentation/viewmodels/map_viewmodel.dart';
import 'package:partiu/features/home/presentation/widgets/event_card/event_card.dart';
import 'package:partiu/features/home/presentation/widgets/event_card/event_card_controller.dart';
import 'package:partiu/screens/chat/chat_screen_refactored.dart';
import 'package:partiu/shared/stores/user_store.dart';
import 'package:partiu/shared/widgets/confetti_celebration.dart';

/// Widget de mapa Google Maps limpo e performático
/// 
/// Responsabilidades:
/// - Renderizar o Google Map
/// - Exibir localização do usuário
/// - Exibir markers com clustering inteligente baseado em zoom
/// - Controlar câmera
/// 
/// Clustering:
/// - Zoom > 10: Apenas markers individuais (SEM clustering)
/// - Zoom <= 10: Clustering ativado (agrupa eventos próximos)
/// - Ao tocar em cluster: zoom in para expandir
/// 
/// Toda lógica de negócio foi extraída para:
/// - MapViewModel (orquestração)
/// - EventMarkerService (markers + clustering)
/// - UserLocationService (localização)
/// - AvatarService (avatares)
/// - MarkerClusterService (algoritmo de clustering)
class GoogleMapView extends StatefulWidget {
  final MapViewModel viewModel;
  final VoidCallback? onPlatformMapCreated;
  /// Callback chamado quando o primeiro scroll do mapa ocorre (para onboarding)
  final VoidCallback? onFirstMapScroll;

  const GoogleMapView({
    super.key,
    required this.viewModel,
    this.onPlatformMapCreated,
    this.onFirstMapScroll,
  });

  @override
  State<GoogleMapView> createState() => GoogleMapViewState();
}

class GoogleMapViewState extends State<GoogleMapView> {
  /// Controller do mapa Google Maps
  GoogleMapController? _mapController;
  
  /// Serviço para gerar markers customizados (com clustering)
  final GoogleEventMarkerService _markerService = GoogleEventMarkerService();
  
  /// Serviço para descoberta de eventos por bounding box
  final MapDiscoveryService _discoveryService = MapDiscoveryService();

  /// Serviço para contagem de pessoas por bounding box
  final PeopleMapDiscoveryService _peopleCountService = PeopleMapDiscoveryService();
  
  /// Markers atuais do mapa (clusterizados)
  Set<Marker> _markers = {};
  
  /// Estilo customizado do mapa carregado de assets
  String? _mapStyle;
  
  /// Zoom atual do mapa (usado para clustering)
  double _currentZoom = 12.0;

  /// Último bounds visível (expandido com buffer) usado para filtrar markers no viewport.
  LatLngBounds? _lastExpandedVisibleBounds;

  /// Cache rápido para mapear eventId -> EventModel no viewport (evita firstWhere em lista grande).
  final Map<String, EventModel> _eventsInViewportById = <String, EventModel>{};

  // Deve estar alinhado com MarkerClusterService._maxClusterZoom
  static const double _clusterZoomThreshold = 11.0;
  
  /// Flag para evitar rebuilds durante animação de câmera
  bool _isAnimating = false;

  /// Flag para evitar rebuild pesado enquanto o usuário move o mapa
  bool _isCameraMoving = false;

  /// Flag para rastrear se já processou o primeiro scroll (para onboarding)
  bool _firstScrollProcessed = false;

  /// Se eventos mudarem durante pan/zoom, faz 1 rebuild quando a câmera ficar idle.
  bool _needsMarkerRebuildAfterCameraIdle = false;

  /// Coalesce de múltiplas invalidações de avatar em um único rebuild
  final Set<String> _pendingAvatarInvalidations = <String>{};
  Timer? _avatarInvalidationDebounce;
  bool _needsMarkerRebuildForAvatar = false;

  Timer? _avatarReadyDebounce;

  Timer? _cameraIdleDebounce;
  static const Duration _cameraIdleDebounceDuration = Duration(milliseconds: 200);

  static const double _viewportBoundsBufferFactor = 1.3;

  MapBounds? _lastRequestedQueryBounds;
  DateTime _lastRequestedQueryAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _minIntervalBetweenContainedBoundsQueries = Duration(seconds: 2);

  bool _isBoundsContained(MapBounds inner, MapBounds outer) {
    return inner.minLat >= outer.minLat &&
        inner.maxLat <= outer.maxLat &&
        inner.minLng >= outer.minLng &&
        inner.maxLng <= outer.maxLng;
  }

  LatLngBounds _expandBounds(LatLngBounds bounds, double factor) {
    final sw = bounds.southwest;
    final ne = bounds.northeast;

    final centerLat = (sw.latitude + ne.latitude) / 2.0;
    final centerLng = (sw.longitude + ne.longitude) / 2.0;

    final halfLatSpan = (ne.latitude - sw.latitude).abs() * factor / 2.0;
    final halfLngSpan = (ne.longitude - sw.longitude).abs() * factor / 2.0;

    double clampLat(double v) => v.clamp(-90.0, 90.0);
    double clampLng(double v) => v.clamp(-180.0, 180.0);

    return LatLngBounds(
      southwest: LatLng(
        clampLat(centerLat - halfLatSpan),
        clampLng(centerLng - halfLngSpan),
      ),
      northeast: LatLng(
        clampLat(centerLat + halfLatSpan),
        clampLng(centerLng + halfLngSpan),
      ),
    );
  }

  bool _boundsContains(LatLngBounds bounds, double lat, double lng) {
    final sw = bounds.southwest;
    final ne = bounds.northeast;

    final minLat = sw.latitude < ne.latitude ? sw.latitude : ne.latitude;
    final maxLat = sw.latitude < ne.latitude ? ne.latitude : sw.latitude;
    final withinLat = lat >= minLat && lat <= maxLat;

    // Normalmente (Brasil) não cruza antimeridiano; ainda assim, trata caso sw.lng > ne.lng.
    final swLng = sw.longitude;
    final neLng = ne.longitude;
    final withinLng = swLng <= neLng ? (lng >= swLng && lng <= neLng) : (lng >= swLng || lng <= neLng);

    return withinLat && withinLng;
  }

  /// Método público para centralizar no usuário
  void centerOnUser() {
    _moveCameraToUserLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    
    // Carregar estilo do mapa de assets
    _loadMapStyle();
    
    // Configurar callback de tap no ViewModel recebido
    debugPrint('🔴 GoogleMapView: Configurando callback onMarkerTap');
    widget.viewModel.onMarkerTap = (event) => _onMarkerTap(event);
    debugPrint('🔴 GoogleMapView: Callback configurado? ${widget.viewModel.onMarkerTap != null}');
    
    // Registrar handler de navegação no MapNavigationService
    MapNavigationService.instance.registerMapHandler((eventId, {bool showConfetti = false}) {
      _handleEventNavigation(eventId, showConfetti: showConfetti);
    });
    debugPrint('🗺️ GoogleMapView: Handler de navegação registrado');
    
    // ✅ Listener para invalidação de avatares do UserStore
    // Quando um avatar é atualizado, limpa cache e regenera markers
    UserStore.instance.avatarInvalidationNotifier.addListener(_onAvatarInvalidated);
    debugPrint('👤 GoogleMapView: Listener de invalidação de avatar registrado');

    // ✅ Listener para quando avatares terminarem de carregar para o cache do MarkerService
    // Isso troca placeholder -> avatar real com debounce (reduz “pisca”).
    _markerService.avatarBitmapsVersion.addListener(_onAvatarBitmapsUpdated);
    unawaited(_markerService.preloadDefaultPins());
    
    // Listener para atualizar markers quando eventos mudarem
    widget.viewModel.addListener(_onEventsChanged);

    // ⚡ Se o Splash/AppInitializer já gerou markers, usa como estado inicial.
    // Isso faz os markers aparecerem junto com o mapa, sem esperar rebuild assíncrono.
    final preloadedMarkers = widget.viewModel.googleMarkers;
    if (preloadedMarkers.isNotEmpty) {
      _markers = preloadedMarkers;
      debugPrint('⚡ GoogleMapView: Usando ${_markers.length} markers pré-carregados do MapViewModel');
    }
    
    // Verificar se eventos e markers já foram pré-carregados pelo AppInitializerService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.viewModel.events.isEmpty && !widget.viewModel.isLoading) {
        debugPrint('🔴 GoogleMapView: Nenhum evento pré-carregado, carregando agora...');
        widget.viewModel.loadNearbyEvents();
      } else {
        debugPrint('✅ GoogleMapView: ${widget.viewModel.events.length} eventos já pré-carregados!');
        debugPrint('⚡ GoogleMapView: Bitmaps já em cache, gerando markers com callbacks...');
        
        // Os BITMAPS foram pré-carregados no AppInitializerService,
        // então a geração de markers será instantânea
        _currentZoom = 12.0; // Zoom padrão - visão regional
        _onEventsChanged();
      }
    });
  }
  
  /// Carrega o estilo do mapa de assets
  Future<void> _loadMapStyle() async {
    try {
      final style = await rootBundle.loadString('assets/map_styles/clean.json');
      if (!mounted) return;
      setState(() {
        _mapStyle = style;
      });
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar estilo do mapa: $e');
    }
  }
  
  /// Callback quando um avatar é invalidado
  /// 
  /// Limpa cache do avatar e regenera markers
  void _onAvatarInvalidated() async {
    final invalidatedUserId = UserStore.instance.avatarInvalidationNotifier.value;
    if (invalidatedUserId == null || invalidatedUserId.isEmpty) return;
    
    debugPrint('👤 GoogleMapView: Avatar invalidado para userId: $invalidatedUserId');

    _pendingAvatarInvalidations.add(invalidatedUserId);

    _avatarInvalidationDebounce?.cancel();
    _avatarInvalidationDebounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;

      final idsToInvalidate = List<String>.from(_pendingAvatarInvalidations);
      _pendingAvatarInvalidations.clear();

      for (final userId in idsToInvalidate) {
        await _markerService.removeCachedAvatar(userId);
      }

      if (widget.viewModel.events.isEmpty) return;

      // Evita rebuild pesado durante pan/zoom.
      if (_isAnimating || _isCameraMoving) {
        _needsMarkerRebuildForAvatar = true;
        return;
      }

      debugPrint('🔄 GoogleMapView: Regenerando markers (debounced) após invalidação de avatar');
      await _rebuildClusteredMarkers();
    });
  }

  void _onAvatarBitmapsUpdated() {
    if (!mounted) return;
    if (widget.viewModel.events.isEmpty) return;

    // Evita rebuild pesado durante pan/zoom.
    if (_isAnimating || _isCameraMoving) {
      _needsMarkerRebuildForAvatar = true;
      return;
    }

    _avatarReadyDebounce?.cancel();
    _avatarReadyDebounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      if (widget.viewModel.events.isEmpty) return;

      // Se a câmera começou a mover durante o debounce, adia para onCameraIdle.
      if (_isAnimating || _isCameraMoving) {
        _needsMarkerRebuildForAvatar = true;
        return;
      }

      await _rebuildClusteredMarkers();
    });
  }
  
  /// Callback quando eventos mudarem
  /// 
  /// Recalcula clusters baseado no zoom atual
  void _onEventsChanged() async {
    if (!mounted) {
      debugPrint('⚠️ GoogleMapView._onEventsChanged: widget não montado, ignorando');
      return;
    }
    
    if (_isAnimating) {
      debugPrint('⚠️ GoogleMapView._onEventsChanged: animação em progresso, ignorando');
      return;
    }
    
    final eventCount = widget.viewModel.events.length;
    debugPrint('🔔 GoogleMapView._onEventsChanged: $eventCount eventos');
    
    if (eventCount > 0) {
      debugPrint('📋 IDs: ${widget.viewModel.events.map((e) => e.id).take(5).join(", ")}...');
    }
    
    await _rebuildClusteredMarkers();
  }

  /// Reconstrói markers com clustering baseado no zoom atual
  /// 
  /// Este método é chamado:
  /// - Quando eventos mudam (listener do ViewModel)
  /// - Quando zoom muda (onCameraIdle)
  Future<void> _rebuildClusteredMarkers() async {
    if (!mounted) {
      debugPrint('⚠️ _rebuildClusteredMarkers: widget não montado');
      return;
    }

    if (_isAnimating || _isCameraMoving) {
      _needsMarkerRebuildAfterCameraIdle = true;
      debugPrint('⚠️ _rebuildClusteredMarkers: câmera em movimento/animação, adiando rebuild');
      return;
    }

    final allEvents = widget.viewModel.events;

    // Garante placeholder pronto para não cair em defaultMarker.
    await _markerService.preloadDefaultPins();

    final eventsByCategory = _applyCategoryFilter(allEvents);
    final bounds = _lastExpandedVisibleBounds;

    final viewportEvents = bounds == null
        ? eventsByCategory
        : eventsByCategory
            .where((event) => _boundsContains(bounds, event.lat, event.lng))
            .toList(growable: false);

    final eventCount = viewportEvents.length;
    final currentMarkerCount = _markers.length;
    
    debugPrint(
      '🔄 _rebuildClusteredMarkers: memory=${allEvents.length}, viewport=$eventCount, markersAtuais=$currentMarkerCount',
    );
    
    // ⚠️ IMPORTANTE: Limpar markers quando não há eventos
    if (eventCount == 0) {
      if (currentMarkerCount > 0) {
        debugPrint('🗑️ Limpando $currentMarkerCount markers da UI (0 eventos)');
        setState(() {
          _markers = {};
        });
        debugPrint('✅ Markers limpos com sucesso!');
      } else {
        debugPrint('ℹ️ Nenhum marker para limpar (já está vazio)');
      }
      return;
    }
    
    final stopwatch = Stopwatch()..start();
    
    debugPrint('🔲 Reconstruindo markers com clustering (zoom: ${_currentZoom.toStringAsFixed(1)}, $eventCount eventos)');
    
    // Gerar markers clusterizados
    final markers = await _markerService.buildClusteredMarkers(
      viewportEvents,
      zoom: _currentZoom,
      onSingleTap: (eventId) {
        debugPrint('🎯 Marker individual tocado: $eventId');
        final event = _eventsInViewportById[eventId] ??
            widget.viewModel.events.firstWhere((e) => e.id == eventId);
        _onMarkerTap(event);
      },
      onClusterTap: (eventsInCluster) {
        debugPrint('🔴 Cluster tocado: ${eventsInCluster.length} eventos');
        _onClusterTap(eventsInCluster);
      },
    );

    _eventsInViewportById
      ..clear()
      ..addEntries(viewportEvents.map((e) => MapEntry(e.id, e)));
    
    if (mounted) {
      setState(() {
        _markers = markers;
      });
      stopwatch.stop();
      debugPrint('✅ GoogleMapView: ${_markers.length} markers clusterizados em ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('🗺️ Markers atualizados na UI');
    }
  }

  List<EventModel> _applyCategoryFilter(List<EventModel> events) {
    final selected = widget.viewModel.selectedCategory;
    if (selected == null || selected.trim().isEmpty) return events;

    final normalized = selected.trim();
    return events.where((event) {
      final category = event.category;
      if (category == null) return false;
      return category.trim() == normalized;
    }).toList(growable: false);
  }

  /// Callback quando cluster é tocado
  /// 
  /// Comportamento:
  /// - Zoom in até desfazer o cluster (zoom > 11 desativa clustering)
  /// - Se zoom já alto, mostra o primeiro evento
  void _onClusterTap(List<EventModel> eventsInCluster) async {
    if (_mapController == null || eventsInCluster.isEmpty) return;
    
    // Se zoom já está alto (>= 16), mostrar primeiro evento
    if (_currentZoom >= 16) {
      debugPrint('📍 Cluster tocado em zoom alto - mostrando primeiro evento');
      _onMarkerTap(eventsInCluster.first);
      return;
    }
    
    // ✅ Em vez de usar apenas média, usar bounds do cluster.
    // Isso evita “cair” numa área vazia quando a posição do cluster/zoom está levemente defasada.
    double minLat = eventsInCluster.first.lat;
    double maxLat = eventsInCluster.first.lat;
    double minLng = eventsInCluster.first.lng;
    double maxLng = eventsInCluster.first.lng;
    for (final event in eventsInCluster.skip(1)) {
      if (event.lat < minLat) minLat = event.lat;
      if (event.lat > maxLat) maxLat = event.lat;
      if (event.lng < minLng) minLng = event.lng;
      if (event.lng > maxLng) maxLng = event.lng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    debugPrint(
      '🔍 Expandindo cluster: ${eventsInCluster.length} eventos, bounds=($minLat,$minLng)-($maxLat,$maxLng)',
    );
    
    // Marcar que está animando para evitar rebuilds intermediários
    _isAnimating = true;
    
    try {
      // Tenta enquadrar todos os eventos do cluster.
      // Em clusters com um único ponto (bounds degenerado), dá fallback para zoom.
      if (minLat == maxLat && minLng == maxLng) {
        // 🎯 Calcular zoom para DESFAZER o cluster
        // Clustering é ativado quando zoom <= 11, então precisamos ir para zoom > 11
        final newZoom = (_currentZoom <= _clusterZoomThreshold)
            ? (eventsInCluster.length > 5 ? 13.0 : 12.0)
            : (_currentZoom + 2).clamp(3.0, 20.0);
        debugPrint(
          '🔍 Cluster em ponto único: zoom ${_currentZoom.toStringAsFixed(1)} → ${newZoom.toStringAsFixed(1)}',
        );
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), newZoom),
        );
      } else {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      }
      
      // Aguardar animação completar
      await Future.delayed(const Duration(milliseconds: 400));
      
    } finally {
      _isAnimating = false;
    }
    
    // 🎯 Atualiza zoom real após animação (bounds define zoom automaticamente)
    try {
      _currentZoom = await _mapController!.getZoomLevel();
    } catch (_) {}
    
    // Limpar cache de clusters para forçar recalculo com novo zoom
    _markerService.clearClusterCache();
    
    debugPrint('🔄 Forçando rebuild de markers após zoom do cluster');
    await _rebuildClusteredMarkers();
  }

  /// Callback quando o mapa é criado
  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    // Sinaliza que o PlatformView do mapa já foi criado (evita tela branca sem feedback)
    widget.onPlatformMapCreated?.call();
    
    // Mover câmera para localização inicial (já carregada)
    if (widget.viewModel.lastLocation != null) {
      await _moveCameraTo(
        widget.viewModel.lastLocation!.latitude,
        widget.viewModel.lastLocation!.longitude,
        zoom: 12.0, // Visão regional para ver mais eventos
      );
    } else {
      await _moveCameraToUserLocation();
    }

    // Fazer busca inicial de eventos na região visível
    // Isso garante que o drawer tenha dados logo ao abrir
    await _triggerInitialEventSearch();
  }

  /// Callback quando a câmera para de se mover
  /// 
  /// Responsável por:
  /// 1. Capturar bounding box visível
  /// 2. Buscar eventos na região
  /// 3. Recalcular clusters se zoom mudou
  Future<void> _onCameraIdle() async {
    _isCameraMoving = false;

    if (_mapController == null || _isAnimating) return;

    _cameraIdleDebounce?.cancel();
    _cameraIdleDebounce = Timer(_cameraIdleDebounceDuration, () {
      if (!mounted) return;
      unawaited(_handleCameraIdleDebounced());
    });
  }

  Future<void> _handleCameraIdleDebounced() async {
    if (_mapController == null || _isAnimating) return;

    try {
      // Obter zoom atual
      final previousZoom = _currentZoom;
      final newZoom = await _mapController!.getZoomLevel();
      final zoomChanged = (newZoom - previousZoom).abs() > 0.5;

      // Recalcular quando cruzar o limiar de clustering, mesmo se a variação for pequena
      final crossedClusterThreshold =
          (previousZoom <= _clusterZoomThreshold && newZoom > _clusterZoomThreshold) ||
          (previousZoom > _clusterZoomThreshold && newZoom <= _clusterZoomThreshold);

      // Atualizar zoom atual
      _currentZoom = newZoom;

      final visibleRegion = await _mapController!.getVisibleRegion();
      final expandedBounds = _expandBounds(visibleRegion, _viewportBoundsBufferFactor);
      _lastExpandedVisibleBounds = expandedBounds;

      // Queries/counters usam bounds EXPANDIDO para reduzir refetch durante pequenos pans.
      final queryBounds = MapBounds.fromLatLngBounds(expandedBounds);
      // Pessoas devem ser determinadas pelo que está DENTRO do frame.
      final peopleBounds = MapBounds.fromLatLngBounds(visibleRegion);
      
      debugPrint('📍 GoogleMapView: Câmera parou (zoom: ${newZoom.toStringAsFixed(1)}, mudou: $zoomChanged)');
      
      // Recalcular clusters se zoom mudou significativamente OU se cruzou o limiar de clustering
      if ((zoomChanged || crossedClusterThreshold) && widget.viewModel.events.isNotEmpty) {
        debugPrint('🔄 GoogleMapView: Zoom mudou - recalculando clusters');
        await _rebuildClusteredMarkers();
      }

      // Se eventos mudaram durante o movimento, faz um rebuild único aqui.
      if (_needsMarkerRebuildAfterCameraIdle && widget.viewModel.events.isNotEmpty) {
        _needsMarkerRebuildAfterCameraIdle = false;
        debugPrint('🔄 GoogleMapView: Rebuild pendente após câmera parar');
        await _rebuildClusteredMarkers();
      }
      
      // Disparar busca de eventos no bounding box
      final now = DateTime.now();
      final withinPrevious = _lastRequestedQueryBounds != null &&
          _isBoundsContained(queryBounds, _lastRequestedQueryBounds!);
      final tooSoon = now.difference(_lastRequestedQueryAt) < _minIntervalBetweenContainedBoundsQueries;

      if (withinPrevious && tooSoon) {
        debugPrint('📦 GoogleMapView: Bounds contido, pulando refetch (janela curta)');
      } else {
        _lastRequestedQueryBounds = queryBounds;
        _lastRequestedQueryAt = now;
        await _discoveryService.loadEventsInBounds(queryBounds);
      }

      // Atualizar contagem/lista de pessoas SOMENTE quando o zoom está próximo
      // (clusters desfeitos). Em zoom out (clustering), isso vira custo alto e
      // não representa a UI (região é grande demais).
      //
      // Importante: pessoas usam o bounds VISÍVEL (frame), não o expandido.
      final viewportActive = _currentZoom > _clusterZoomThreshold;
      _peopleCountService.setViewportActive(viewportActive);
      if (viewportActive) {
        await _peopleCountService.loadPeopleCountInBounds(peopleBounds);
      }

      // Se houve invalidação de avatar enquanto a câmera se movia, faz 1 rebuild aqui.
      if (_needsMarkerRebuildForAvatar && widget.viewModel.events.isNotEmpty) {
        _needsMarkerRebuildForAvatar = false;
        debugPrint('🔄 GoogleMapView: Regenerando markers após câmera parar (avatar invalidado)');
        await _rebuildClusteredMarkers();
      }
    } catch (error) {
      debugPrint('⚠️ GoogleMapView: Erro ao capturar bounding box: $error');
    }
  }

  void _onCameraMoveStarted() {
    _isCameraMoving = true;
    // Evita acumular downloads enquanto o usuário está pan/zoom no mapa.
    UserStore.instance.cancelAvatarPreloads();
    
    // Detectar primeiro scroll do usuário (para onboarding)
    _checkFirstMapScroll();
  }
  
  /// Verifica se este é o primeiro scroll e dispara callback de onboarding
  Future<void> _checkFirstMapScroll() async {
    debugPrint('🎯 [GoogleMapView] _checkFirstMapScroll iniciado');
    debugPrint('   _firstScrollProcessed: $_firstScrollProcessed');
    
    if (_firstScrollProcessed) {
      debugPrint('   ⏭️ Primeiro scroll já processado, ignorando');
      return;
    }
    _firstScrollProcessed = true;
    
    // Verificar se onboarding ainda não foi completado
    debugPrint('   🔍 Verificando shouldShowOnboarding...');
    final shouldShow = await OnboardingService.instance.shouldShowOnboarding();
    debugPrint('   📊 shouldShow: $shouldShow');
    
    if (shouldShow) {
      // O primeiro scroll já ocorreu em outra sessão e o onboarding ainda
      // não foi completado. Dispara o callback para exibir o onboarding.
      debugPrint('   ✅ Disparando callback onFirstMapScroll (onboarding pendente)');
      debugPrint('   🎯 widget.onFirstMapScroll is null? ${widget.onFirstMapScroll == null}');
      widget.onFirstMapScroll?.call();
      return;
    }
    
    // Verifica se é realmente o primeiro scroll (ainda não marcado)
    debugPrint('   🔍 Verificando hasFirstMapScrollOccurred...');
    final alreadyScrolled = await OnboardingService.instance.hasFirstMapScrollOccurred();
    debugPrint('   📊 alreadyScrolled: $alreadyScrolled');
    
    if (!alreadyScrolled) {
      // Marcar que ocorreu o primeiro scroll
      debugPrint('   ✍️ Marcando primeiro scroll...');
      await OnboardingService.instance.markFirstMapScroll();
      
      // Disparar callback para mostrar onboarding
      debugPrint('   ✅ Disparando callback onFirstMapScroll (primeiro scroll)');
      debugPrint('   🎯 widget.onFirstMapScroll is null? ${widget.onFirstMapScroll == null}');
      widget.onFirstMapScroll?.call();
    } else {
      debugPrint('   ⏭️ Scroll já foi marcado anteriormente, não disparando callback');
    }
  }

  /// Faz busca inicial de eventos na região visível
  /// 
  /// Chamado logo após o mapa ser criado para garantir
  /// que o drawer tenha dados ao abrir pela primeira vez.
  /// Também inicializa o zoom para clustering.
  Future<void> _triggerInitialEventSearch() async {
    if (_mapController == null) return;

    try {
      // Pequeno delay para garantir que o mapa terminou de carregar
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Obter zoom inicial para clustering
      _currentZoom = await _mapController!.getZoomLevel();
      debugPrint('🔲 GoogleMapView: Zoom inicial: ${_currentZoom.toStringAsFixed(1)}');
      
      final visibleRegion = await _mapController!.getVisibleRegion();
      _lastExpandedVisibleBounds = _expandBounds(visibleRegion, _viewportBoundsBufferFactor);
      final bounds = MapBounds.fromLatLngBounds(visibleRegion);
      
      debugPrint('🎯 GoogleMapView: Busca inicial de eventos em $bounds');
      
      // Forçar busca imediata (ignora debounce)
      await _discoveryService.forceRefresh(bounds);

      // Contagem/lista de pessoas só faz sentido quando zoom está próximo
      // (clusters desfeitos). Em zoom out, não fazemos preload.
      final viewportActive = _currentZoom > _clusterZoomThreshold;
      _peopleCountService.setViewportActive(viewportActive);
      if (viewportActive) {
        await _peopleCountService.forceRefresh(bounds);
      }
      
      // Gerar markers iniciais com clustering
      if (widget.viewModel.events.isNotEmpty) {
        await _rebuildClusteredMarkers();
      }
    } catch (error) {
      debugPrint('⚠️ GoogleMapView: Erro na busca inicial: $error');
    }
  }

  /// Move a câmera para a localização do usuário
  Future<void> _moveCameraToUserLocation() async {
    final result = await widget.viewModel.getUserLocation();

    // Exibir mensagem de erro se houver
    if (result.hasError && mounted) {
      _showMessage(result.errorMessage!);
    }

    // Mover câmera
    await _moveCameraTo(
      result.location.latitude,
      result.location.longitude,
      zoom: 12.0, // Visão regional para ver mais eventos
    );
  }

  /// Move a câmera para uma coordenada específica
  Future<void> _moveCameraTo(
    double lat,
    double lng, {
    double zoom = 14.0,
  }) async {
    if (_mapController == null) return;

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, lng),
            zoom: zoom,
          ),
        ),
      );
    } catch (e) {
      // Falha silenciosa - câmera continua onde está
    }
  }

  /// Exibe mensagem para o usuário
  void _showMessage(String message) {
    if (!mounted) return;

    ToastService.showInfo(message: message);
  }

  /// Handler de navegação chamado pelo MapNavigationService
  /// 
  /// Responsável por:
  /// 1. Encontrar o evento na lista de eventos carregados
  /// 2. Mover câmera para o evento
  /// 3. Abrir o EventCard
  /// 
  /// [showConfetti] - Se true, mostra confetti ao abrir o card (usado após criar evento)
  void _handleEventNavigation(String eventId, {bool showConfetti = false}) async {
    debugPrint('🗺️ [GoogleMapView] Navegando para evento: $eventId (confetti: $showConfetti)');
    
    if (!mounted) return;
    
    // Buscar evento na lista de eventos carregados
    final event = widget.viewModel.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () {
        debugPrint('⚠️ [GoogleMapView] Evento não encontrado na lista: $eventId');
        // Se não encontrou, tentar recarregar eventos
        widget.viewModel.loadNearbyEvents();
        throw Exception('Evento não encontrado');
      },
    );
    
    debugPrint('✅ [GoogleMapView] Evento encontrado: ${event.title}');
    
    // Mover câmera para o evento
    if (_mapController != null) {
      final target = LatLng(event.lat, event.lng);
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(target, 15.0),
      );
      debugPrint('📍 [GoogleMapView] Câmera movida para: ${event.title}');
    }
    
    // Aguardar animação da câmera
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Abrir EventCard (com confetti se for evento recém-criado)
    _onMarkerTap(event, showConfetti: showConfetti);
  }

  /// Callback quando usuário toca em um marker
  /// 
  /// [showConfetti] - Se true, mostra confetti ao abrir o card (usado após criar evento)
  void _onMarkerTap(EventModel event, {bool showConfetti = false}) {
    debugPrint('🔴🔴🔴 GoogleMapView._onMarkerTap CHAMADO! 🔴🔴🔴');
    debugPrint('🔴 GoogleMapView._onMarkerTap called for: ${event.id} - ${event.title}');
    debugPrint('📦 EventModel pré-carregado:');
    debugPrint('   - locationName: ${event.locationName}');
    debugPrint('   - privacyType: ${event.privacyType}');
    debugPrint('   - creatorFullName: ${event.creatorFullName}');
    debugPrint('   - scheduleDate: ${event.scheduleDate}');
    debugPrint('   - userApplication: ${event.userApplication?.status.value}');
    debugPrint('   - participants: ${event.participants?.length ?? 0}');
    
    // Criar controller com evento pré-carregado (evita query Firestore)
    final controller = EventCardController(
      eventId: event.id,
      preloadedEvent: event,
    );
    
    debugPrint('🔴 Controller criado com dados pré-carregados');
    
    // NÃO chamar load() aqui - deixar o EventCard chamar quando necessário
    // O controller já tem todos os dados essenciais via preloadedEvent
    
    debugPrint('🔴 Abrindo showModalBottomSheet');
    
    // Mostrar confetti se for evento recém-criado
    if (showConfetti) {
      ConfettiOverlay.show(context);
    }
    
    // Abrir o card imediatamente
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(
        maxWidth: 500,
      ),
      builder: (context) => EventCard(
        controller: controller,
        onActionPressed: () async {
          // Capturar o navigator antes de fechar o modal
          final navigator = Navigator.of(context);
          
          // Fechar o card
          navigator.pop();
          
          // Se for o criador ou estiver aprovado, navegar para o chat
          if (controller.isCreator || controller.isApproved) {
            // Usar dados do evento pré-carregado
            final eventName = event.title;
            final emoji = event.emoji;
            
            // Criar User com dados do evento usando campos corretos do SessionManager
            final chatUser = app_user.User.fromDocument({
              'userId': 'event_${event.id}',
              'fullName': eventName,
              'photoUrl': emoji,
              'gender': '',
              'birthDay': 1,
              'birthMonth': 1,
              'birthYear': 2000,
              'jobTitle': '',
              'bio': '',
              'country': '',
              'locality': '',
              'latitude': 0.0,
              'longitude': 0.0,
              'status': 'active',
              'level': '',
              'isVerified': false,
              'registrationDate': DateTime.now().toIso8601String(),
              'lastLoginDate': DateTime.now().toIso8601String(),
              'totalLikes': 0,
              'totalVisits': 0,
              'isOnline': false,
            });
            
            // Verificar se usuário está bloqueado
            final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
            if (currentUserId.isNotEmpty && 
                BlockService().isBlockedCached(currentUserId, event.createdBy)) {
              final i18n = AppLocalizations.of(context);
              ToastService.showWarning(
                message: i18n.translate('user_blocked_cannot_message'),
              );
              return;
            }
            
            // Usar o navigator capturado anteriormente
            navigator.push(
              MaterialPageRoute(
                builder: (context) => ChatScreenRefactored(
                  user: chatUser,
                  isEvent: true,
                  eventId: event.id,
                ),
              ),
            );
          }
        },
      ),
    ).whenComplete(() {
      // Garantir limpeza do controller ao fechar o modal
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Widget limpo - apenas UI
    // Toda lógica delegada ao ViewModel
    return GoogleMap(
      style: _mapStyle,
      // Callback de criação
      onMapCreated: _onMapCreated,

      onCameraMoveStarted: _onCameraMoveStarted,

      // Callback quando câmera para (após movimento)
      onCameraIdle: _onCameraIdle,

      // Posição inicial (São Paulo) - zoom afastado para ver região
      initialCameraPosition: const CameraPosition(
        target: LatLng(-23.5505, -46.6333),
        zoom: 10.0,
      ),
      
      // Permitir zoom de 3.0 (visão continental) até 20.0 (visão de rua detalhada)
      minMaxZoomPreference: const MinMaxZoomPreference(3.0, 20.0),

      // Markers customizados gerados pelo GoogleEventMarkerService
      markers: _markers,

      // Configurações do mapa
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapType: MapType.normal,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      tiltGesturesEnabled: false,
    );
  }

  @override
  void dispose() {
    _cameraIdleDebounce?.cancel();
    _avatarInvalidationDebounce?.cancel();
    _avatarReadyDebounce?.cancel();
    widget.viewModel.removeListener(_onEventsChanged);
    UserStore.instance.avatarInvalidationNotifier.removeListener(_onAvatarInvalidated);
    _markerService.avatarBitmapsVersion.removeListener(_onAvatarBitmapsUpdated);
    MapNavigationService.instance.unregisterMapHandler();
    debugPrint('🗺️ GoogleMapView: Handler de navegação removido');
    _markerService.clearCache(); // Limpar cache de markers e clusters
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }
}
