import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/services/location/geo_utils.dart';
import 'package:partiu/services/location/distance_isolate.dart';
import 'package:partiu/services/location/location_stream_controller.dart';

/// Serviço principal para queries de localização com filtro de raio
/// 
/// Responsabilidades:
/// - Carregar eventos dentro do raio do usuário
/// - Cache com TTL (30 segundos)
/// - Bounding box para queries otimizadas
/// - Isolate para cálculo de distâncias sem jank
/// - Stream de atualizações automáticas
class LocationQueryService {
  /// Singleton
  static final LocationQueryService _instance =
      LocationQueryService._internal();
  factory LocationQueryService() => _instance;
  LocationQueryService._internal() {
    _initializeListeners();
  }

  /// Cache de localização do usuário
  UserLocationCache? _userLocationCache;

  /// Cache de eventos
  EventsCache? _eventsCache;

  /// Filtros atuais
  EventFilterOptions _currentFilters = EventFilterOptions();

  /// Stream controller para eventos
  final _eventsStreamController =
      StreamController<List<EventWithDistance>>.broadcast();

  /// TTL do cache (30 segundos)
  static const Duration cacheTTL = Duration(seconds: 30);

  /// Stream de eventos
  Stream<List<EventWithDistance>> get eventsStream =>
      _eventsStreamController.stream;

  /// Inicializa listeners para mudanças de raio/localização
  void _initializeListeners() {
    final streamController = LocationStreamController();

    // Listener de mudanças de raio
    streamController.radiusStream.listen((radiusKm) {
      debugPrint('🔄 LocationQueryService: Raio mudou para $radiusKm km');
      _invalidateEventsCache();
      _loadAndEmitEvents(radiusKm: radiusKm);
    });

    // Listener de reload manual
    streamController.reloadStream.listen((_) {
      debugPrint('🔄 LocationQueryService: Reload manual solicitado');
      _invalidateAllCaches();
      _loadAndEmitEvents();
    });
  }

  /// Atualiza os filtros e recarrega eventos
  void updateFilters(EventFilterOptions filters) {
    _currentFilters = filters;
    debugPrint('🔍 LocationQueryService.updateFilters: radiusKm = ${filters.radiusKm}');
    debugPrint('🔍 LocationQueryService.updateFilters: gender = ${filters.gender}');
    debugPrint('🔍 LocationQueryService.updateFilters: age = ${filters.minAge}-${filters.maxAge}');
    debugPrint('🔍 LocationQueryService.updateFilters: verified = ${filters.isVerified}');
    debugPrint('🔍 LocationQueryService.updateFilters: interests = ${filters.interests}');
    debugPrint('🔄 LocationQueryService: Filtros atualizados');
    _invalidateEventsCache();
    _loadAndEmitEvents(radiusKm: filters.radiusKm);
    
    // Emitir reload para notificar outros listeners (ex: AppleMapViewModel)
    LocationStreamController().emitReload();
  }

  /// Busca eventos dentro do raio - versão única (sem stream)
  /// 
  /// Uso: Quando precisa de uma consulta pontual
  Future<List<EventWithDistance>> getEventsWithinRadiusOnce({
    double? customRadiusKm,
    EventFilterOptions? filters,
  }) async {
    try {
      final activeFilters = filters ?? _currentFilters;

      // 1. Carregar localização do usuário
      final userLocation = await _getUserLocation();
      debugPrint('📍 LocationQueryService: User Location: ${userLocation.latitude}, ${userLocation.longitude}');

      // 2. Obter raio (prioridade: customRadiusKm → filters.radiusKm → Firestore)
      final radiusKm = customRadiusKm ?? activeFilters.radiusKm ?? await _getUserRadius();
      debugPrint('🔍 getEventsWithinRadiusOnce: radiusKm FINAL = $radiusKm (custom=$customRadiusKm, filters=${activeFilters.radiusKm})');
      debugPrint('📍 LocationQueryService: Radius: ${radiusKm}km');

      // 3. Verificar cache de eventos (apenas se filtros não mudaram)
      // Nota: Para cache perfeito com filtros, precisaríamos incluir filtros na chave do cache
      // Por simplicidade, invalidamos cache ao mudar filtros
      if (_eventsCache != null &&
          !_eventsCache!.isExpired &&
          _eventsCache!.radiusKm == radiusKm) {
        debugPrint('✅ LocationQueryService: Usando cache de eventos');
        return _eventsCache!.events;
      }

      // 4. Calcular bounding box
      final boundingBox = GeoUtils.calculateBoundingBox(
        centerLat: userLocation.latitude,
        centerLng: userLocation.longitude,
        radiusKm: radiusKm,
      );

      // 5. Query Firestore (primeira filtragem rápida - Bounding Box)
      final candidateEvents = await _filterByBoundingBox(boundingBox);

      // 6. Buscar criadores e unificar dados (Orquestração)
      final unifiedEvents = await _enrichEventsWithCreators(candidateEvents);
      debugPrint('📊 LocationQueryService: ${unifiedEvents.length} eventos ANTES dos filtros avançados');

      // 7. Filtros em memória (Gender, Age, Verified, Interests) - Agora baseados no CRIADOR
      debugPrint('🔍 Filtros ativos: gender=${activeFilters.gender}, age=${activeFilters.minAge}-${activeFilters.maxAge}, verified=${activeFilters.isVerified}, interests=${activeFilters.interests}');
      
      var filteredEvents = _filterByGender(unifiedEvents, activeFilters.gender);
      debugPrint('📊 Após filtro de gênero: ${filteredEvents.length} eventos');
      
      filteredEvents = _filterByAge(filteredEvents, activeFilters.minAge, activeFilters.maxAge);
      debugPrint('📊 Após filtro de idade: ${filteredEvents.length} eventos');
      
      filteredEvents = _filterByVerified(filteredEvents, activeFilters.isVerified);
      debugPrint('📊 Após filtro verified: ${filteredEvents.length} eventos');
      
      filteredEvents = _filterByInterests(filteredEvents, activeFilters.interests);
      debugPrint('📊 Após filtro de interesses: ${filteredEvents.length} eventos');

      // 8. Filtrar com isolate (distância exata e cálculos pesados)
      final finalEvents = await _filterByDistanceIsolate(
        events: filteredEvents,
        centerLat: userLocation.latitude,
        centerLng: userLocation.longitude,
        radiusKm: radiusKm,
      );
      debugPrint('📊 Após filtro de distância (Isolate): ${finalEvents.length} eventos');

      // 9. Atualizar cache
      _eventsCache = EventsCache(
        events: finalEvents,
        radiusKm: radiusKm,
        timestamp: DateTime.now(),
      );

      debugPrint(
          '✅ LocationQueryService: ${finalEvents.length} eventos retornados após todos os filtros (Orquestrado)');

      return finalEvents;
    } catch (e) {
      debugPrint('❌ LocationQueryService: Erro ao buscar eventos: $e');
      return [];
    }
  }

  /// Busca eventos dentro do raio - versão stream (atualização automática)
  /// 
  /// Uso: Quando precisa de atualizações em tempo real
  Stream<List<EventWithDistance>> getEventsWithinRadiusStream({
    double? customRadiusKm,
  }) async* {
    while (true) {
      final events = await getEventsWithinRadiusOnce(
        customRadiusKm: customRadiusKm,
      );
      yield events;

      // Aguardar próxima atualização
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// Carrega eventos e emite no stream principal
  Future<void> _loadAndEmitEvents({double? radiusKm}) async {
    final events = await getEventsWithinRadiusOnce(customRadiusKm: radiusKm);
    if (!_eventsStreamController.isClosed) {
      _eventsStreamController.add(events);
    }
  }

  /// Busca localização do usuário (com cache)
  Future<UserLocationCache> _getUserLocation() async {
    // Verificar cache
    if (_userLocationCache != null && !_userLocationCache!.isExpired) {
      debugPrint('✅ LocationQueryService: Usando cache de localização (${_userLocationCache!.latitude}, ${_userLocationCache!.longitude})');
      return _userLocationCache!;
    }

    // Buscar do Firestore
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('❌ LocationQueryService._getUserLocation: userId é null');
      throw Exception('Usuário não autenticado');
    }

    debugPrint('🔍 LocationQueryService: Buscando localização do usuário em Users/$userId');
    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();

    if (!userDoc.exists || userDoc.data() == null) {
      debugPrint('❌ LocationQueryService: Documento do usuário NÃO ENCONTRADO em Users/$userId');
      throw Exception('Documento do usuário não existe em Users/$userId');
    }

    final data = userDoc.data()!;
    debugPrint('🔍 LocationQueryService: Documento encontrado, verificando campos...');
    debugPrint('🔍 LocationQueryService: Campos disponíveis: ${data.keys.toList()}');
    
    final latitude = data['latitude'] as double?;
    final longitude = data['longitude'] as double?;
    
    debugPrint('🔍 LocationQueryService: latitude = $latitude');
    debugPrint('🔍 LocationQueryService: longitude = $longitude');

    if (latitude == null || longitude == null) {
      debugPrint('❌ LocationQueryService: Campos latitude/longitude AUSENTES!');
      throw Exception('Campos latitude/longitude ausentes no documento Users/$userId');
    }

    // Atualizar cache
    debugPrint('✅ LocationQueryService: Localização carregada com sucesso ($latitude, $longitude)');
    _userLocationCache = UserLocationCache(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );

    return _userLocationCache!;
  }

  /// Busca raio do usuário
  Future<double> _getUserRadius() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 25.0; // Default

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final radiusKm = userDoc.data()!['radiusKm'] as double?;
        return radiusKm ?? 25.0;
      }
    } catch (e) {
      debugPrint('❌ LocationQueryService: Erro ao buscar raio: $e');
    }

    return 25.0; // Default
  }

  /// Inicializa dados de localização do usuário no Firestore
  /// 
  /// Útil para garantir que os campos necessários existem
  Future<void> initializeUserLocation({
    required double latitude,
    required double longitude,
    double? radiusKm,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('Users').doc(userId).set({
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm ?? 25.0,
        'radiusUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ LocationQueryService: Dados de localização inicializados');
      
      // Invalidar cache para forçar reload
      _invalidateLocationCache();
    } catch (e) {
      debugPrint('❌ LocationQueryService: Erro ao inicializar localização: $e');
    }
  }

  /// Query Firestore com bounding box (primeira filtragem)
  Future<List<EventLocation>> _filterByBoundingBox(
    Map<String, double> boundingBox,
  ) async {
    debugPrint('📦 LocationQueryService: Bounding Box: $boundingBox');

    final eventsQuery = await FirebaseFirestore.instance
        .collection('events')
        .where('location.latitude', isGreaterThanOrEqualTo: boundingBox['minLat'])
        .where('location.latitude', isLessThanOrEqualTo: boundingBox['maxLat'])
        .get();

    debugPrint('📦 LocationQueryService: Firestore returned ${eventsQuery.docs.length} docs based on latitude');

    final events = <EventLocation>[];

    for (final doc in eventsQuery.docs) {
      final data = doc.data();
      final location = data['location'] as Map<String, dynamic>?;
      final latitude = location?['latitude'] as double?;
      final longitude = location?['longitude'] as double?;

      if (latitude == null || longitude == null) {
         debugPrint('⚠️ LocationQueryService: Event ${doc.id} missing lat/lng. Data: $data');
      }

      if (latitude != null && longitude != null) {
        // Filtro adicional de longitude (Firestore só permite 1 range query)
        if (longitude >= boundingBox['minLng']! &&
            longitude <= boundingBox['maxLng']!) {
          events.add(
            EventLocation(
              eventId: doc.id,
              latitude: latitude,
              longitude: longitude,
              eventData: data,
            ),
          );
        } else {
             debugPrint('⚠️ LocationQueryService: Event ${doc.id} excluded by longitude. Event Lng: $longitude, Range: ${boundingBox['minLng']} - ${boundingBox['maxLng']}');
        }
      }
    }

    debugPrint(
        '📦 LocationQueryService: ${events.length} eventos candidatos do Firestore (Bounding Box)');

    return events;
  }

  /// Busca criadores e unifica com eventos
  Future<List<EventLocation>> _enrichEventsWithCreators(List<EventLocation> events) async {
    if (events.isEmpty) return [];

    debugPrint('🔍 _enrichEventsWithCreators: Processando ${events.length} eventos');

    // Extrair IDs dos criadores
    final creatorIds = events
        .map((e) {
          final creatorId = e.eventData['creatorId'] as String?;
          final createdBy = e.eventData['createdBy'] as String?;
          debugPrint('   Evento ${e.eventId}: creatorId=$creatorId, createdBy=$createdBy');
          return creatorId ?? createdBy;
        })
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();

    debugPrint('🔍 _enrichEventsWithCreators: ${creatorIds.length} creatorIds únicos encontrados');
    debugPrint('🔍 Creator IDs: $creatorIds');

    if (creatorIds.isEmpty) {
      debugPrint('⚠️ _enrichEventsWithCreators: Nenhum creatorId encontrado nos eventos!');
      return events;
    }

    // Buscar criadores em batches (limite de 30 do Firestore para 'in')
    final creatorsMap = <String, Map<String, dynamic>>{};
    final chunks = _chunkList(creatorIds, 30);

    debugPrint('🔍 _enrichEventsWithCreators: Buscando ${chunks.length} batches de criadores em Users...');

    for (final chunk in chunks) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('Users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        debugPrint('🔍 Batch retornou ${query.docs.length} criadores');

        for (final doc in query.docs) {
          creatorsMap[doc.id] = doc.data();
          debugPrint('   ✅ Creator ${doc.id} encontrado');
        }
      } catch (e) {
        debugPrint('❌ Erro ao buscar batch de criadores: $e');
      }
    }

    debugPrint('🔍 _enrichEventsWithCreators: ${creatorsMap.length} criadores carregados no mapa');

    // Unificar dados
    final enrichedEvents = <EventLocation>[];
    for (final event in events) {
      final creatorId = (event.eventData['creatorId'] ?? event.eventData['createdBy']) as String?;
      
      if (creatorId != null && creatorsMap.containsKey(creatorId)) {
        // Criar cópia dos dados do evento e adicionar dados do criador
        final newEventData = Map<String, dynamic>.from(event.eventData);
        newEventData['creator'] = creatorsMap[creatorId];
        
        debugPrint('   ✅ Evento ${event.eventId}: Creator ${creatorId} ADICIONADO');
        
        enrichedEvents.add(EventLocation(
          eventId: event.eventId,
          latitude: event.latitude,
          longitude: event.longitude,
          eventData: newEventData,
        ));
      } else {
        // Se não achou criador, mantém evento original (ou descarta? Vamos manter por segurança)
        debugPrint('   ⚠️ Evento ${event.eventId}: Creator $creatorId NÃO ENCONTRADO no mapa');
        enrichedEvents.add(event);
      }
    }

    return enrichedEvents;
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, (i + chunkSize) > list.length ? list.length : (i + chunkSize)));
    }
    return chunks;
  }

  // --- FILTROS EM MEMÓRIA (Baseados no Criador) ---

  List<EventLocation> _filterByGender(List<EventLocation> events, String? gender) {
    if (gender == null || gender == 'all') return events;
    
    return events.where((e) {
      final creator = e.eventData['creator'] as Map<String, dynamic>?;
      if (creator == null) return false; // Se filtrar por gênero e não tem criador, remove
      return creator['gender'] == gender;
    }).toList();
  }

  List<EventLocation> _filterByAge(List<EventLocation> events, int? min, int? max) {
    if (min == null && max == null) {
      debugPrint('🔍 _filterByAge: Filtro desabilitado (min=null, max=null)');
      return events;
    }
    
    debugPrint('🔍 _filterByAge: Filtrando ${events.length} eventos com faixa ${min ?? 0}-${max ?? 100}');
    
    final filtered = events.where((e) {
      final creator = e.eventData['creator'] as Map<String, dynamic>?;
      if (creator == null) {
        debugPrint('❌ Evento ${e.eventId}: creator é NULL');
        return false;
      }

      // Tentar múltiplas formas de obter idade
      dynamic ageValue = creator['age'];
      
      // Se age não existir, tentar calcular de birthYear
      if (ageValue == null) {
        final birthYear = creator['birthYear'];
        if (birthYear != null) {
          final currentYear = DateTime.now().year;
          final parsedYear = birthYear is int ? birthYear : int.tryParse(birthYear.toString());
          if (parsedYear != null) {
            ageValue = currentYear - parsedYear;
            debugPrint('🔍 Evento ${e.eventId}: age calculada de birthYear: $ageValue');
          }
        }
      }
      
      if (ageValue == null) {
        debugPrint('❌ Evento ${e.eventId}: age e birthYear são NULL no creator');
        debugPrint('   Creator keys: ${creator.keys.toList()}');
        return false;
      }
      
      // Converter para int
      final age = ageValue is int ? ageValue : int.tryParse(ageValue.toString());
      
      if (age == null) {
        debugPrint('❌ Evento ${e.eventId}: Não foi possível converter age para int (valor: $ageValue)');
        return false;
      }
      
      final userMin = min ?? 0;
      final userMax = max ?? 100;
      
      final isInRange = age >= userMin && age <= userMax;
      
      if (!isInRange) {
        debugPrint('❌ Evento ${e.eventId}: Creator age=$age FORA da faixa $userMin-$userMax');
      } else {
        debugPrint('✅ Evento ${e.eventId}: Creator age=$age DENTRO da faixa $userMin-$userMax');
      }
      
      return isInRange;
    }).toList();
    
    debugPrint('🔍 _filterByAge: ${filtered.length} eventos passaram no filtro');
    return filtered;
  }

  List<EventLocation> _filterByVerified(List<EventLocation> events, bool? isVerified) {
    if (isVerified == null || !isVerified) return events;
    
    return events.where((e) {
      final creator = e.eventData['creator'] as Map<String, dynamic>?;
      if (creator == null) return false;
      return creator['isVerified'] == true;
    }).toList();
  }

  List<EventLocation> _filterByInterests(List<EventLocation> events, List<String>? interests) {
    if (interests == null || interests.isEmpty) return events;
    
    return events.where((e) {
      final creator = e.eventData['creator'] as Map<String, dynamic>?;
      if (creator == null) return false;
      
      final creatorInterests = List<String>.from(creator['interests'] ?? []);
      // Retorna true se tiver pelo menos um interesse em comum
      return creatorInterests.any((i) => interests.contains(i));
    }).toList();
  }

  /// Filtra eventos com isolate (segunda filtragem precisa)
  Future<List<EventWithDistance>> _filterByDistanceIsolate({
    required List<EventLocation> events,
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) async {
    if (events.isEmpty) return [];

    final request = DistanceFilterRequest(
      events: events,
      centerLat: centerLat,
      centerLng: centerLng,
      radiusKm: radiusKm,
    );

    // Usar compute() para executar em isolate
    final filteredEvents = await compute(filterEventsByDistance, request);

    debugPrint(
        '🎯 LocationQueryService: ${filteredEvents.length} eventos filtrados por distância (Isolate)');

    return filteredEvents;
  }

  /// Invalida cache de localização
  void _invalidateLocationCache() {
    _userLocationCache = null;
    debugPrint('🗑️ LocationQueryService: Cache de localização invalidado');
  }

  /// Invalida cache de eventos
  void _invalidateEventsCache() {
    _eventsCache = null;
    debugPrint('🗑️ LocationQueryService: Cache de eventos invalidado');
  }

  /// Invalida todos os caches
  void _invalidateAllCaches() {
    _invalidateLocationCache();
    _invalidateEventsCache();
  }

  /// Força reload manual
  void forceReload() {
    _invalidateAllCaches();
    _loadAndEmitEvents();
  }

  /// Dispose
  void dispose() {
    _eventsStreamController.close();
  }
}

/// Cache de localização do usuário
class UserLocationCache {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  UserLocationCache({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// Verifica se o cache está expirado
  bool get isExpired {
    return DateTime.now().difference(timestamp) >
        LocationQueryService.cacheTTL;
  }
}

/// Cache de eventos
class EventsCache {
  final List<EventWithDistance> events;
  final double radiusKm;
  final DateTime timestamp;

  EventsCache({
    required this.events,
    required this.radiusKm,
    required this.timestamp,
  });

  /// Verifica se o cache está expirado
  bool get isExpired {
    return DateTime.now().difference(timestamp) >
        LocationQueryService.cacheTTL;
  }
}

/// Opções de filtro para eventos
class EventFilterOptions {
  final String? gender;
  final int? minAge;
  final int? maxAge;
  final bool? isVerified;
  final List<String>? interests;
  final double? radiusKm;

  EventFilterOptions({
    this.gender,
    this.minAge,
    this.maxAge,
    this.isVerified,
    this.interests,
    this.radiusKm,
  });
}
