import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/core/models/user.dart' as app_user;
import 'package:partiu/core/services/location_service.dart';
import 'package:partiu/core/utils/interests_helper.dart';
import 'package:partiu/features/home/data/models/map_bounds.dart';
import 'package:partiu/services/location/people_cloud_service.dart';
import 'package:partiu/shared/repositories/user_repository.dart';
import 'package:partiu/shared/stores/user_store.dart';

/// Serviço exclusivo para descoberta de pessoas por bounding box do mapa.
///
/// Implementa padrão similar ao MapDiscoveryService (eventos):
/// - `nearbyPeople`: lista reativa de pessoas no bounds atual
/// - `nearbyPeopleCount`: contador total de candidatos (antes do limit)
/// - Debounce + cache TTL para evitar spam durante pan/zoom
class PeopleMapDiscoveryService {
  static final PeopleMapDiscoveryService _instance = PeopleMapDiscoveryService._internal();
  factory PeopleMapDiscoveryService() => _instance;

  PeopleMapDiscoveryService._internal();

  final PeopleCloudService _cloudService = PeopleCloudService();
  final LocationService _locationService = LocationService();
  final UserRepository _userRepository = UserRepository();

  /// Lista de pessoas próximas (similar a MapDiscoveryService.nearbyEvents)
  final ValueNotifier<List<app_user.User>> nearbyPeople = ValueNotifier<List<app_user.User>>([]);
  
  final ValueNotifier<int> nearbyPeopleCount = ValueNotifier<int>(0);
  final ValueNotifier<MapBounds?> currentBounds = ValueNotifier<MapBounds?>(null);

  static const Duration cacheTTL = Duration(seconds: 10);
  static const Duration debounceTime = Duration(milliseconds: 500);

  Timer? _debounceTimer;
  MapBounds? _pendingBounds;

  List<app_user.User> _cachedPeople = [];
  int _cachedCount = 0;
  DateTime _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastQuadkey;

  bool _shouldUseCache(String quadkey) {
    if (_lastQuadkey != quadkey) return false;
    final elapsed = DateTime.now().difference(_lastFetchTime);
    return elapsed < cacheTTL;
  }

  Future<void> loadPeopleCountInBounds(MapBounds bounds) async {
    debugPrint('📍 [PeopleMapDiscovery] loadPeopleCountInBounds chamado');
    debugPrint('   📐 Bounds: minLat=${bounds.minLat.toStringAsFixed(4)}, maxLat=${bounds.maxLat.toStringAsFixed(4)}');
    
    currentBounds.value = bounds;
    _pendingBounds = bounds;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceTime, () {
      final b = _pendingBounds;
      if (b != null) {
        _pendingBounds = null;
        unawaited(_executeQuery(b));
      }
    });
  }

  Future<void> forceRefresh(MapBounds bounds) async {
    debugPrint('🔄 [PeopleMapDiscovery] forceRefresh chamado');
    currentBounds.value = bounds;
    _debounceTimer?.cancel();
    _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(0);
    await _executeQuery(bounds);
  }

  Future<void> refreshCurrentBounds() async {
    debugPrint('🔄 [PeopleMapDiscovery] refreshCurrentBounds chamado');
    final bounds = currentBounds.value;
    if (bounds == null) {
      debugPrint('⚠️ [PeopleMapDiscovery] currentBounds é null - nada a fazer');
      return;
    }
    debugPrint('   📐 Bounds atual: minLat=${bounds.minLat.toStringAsFixed(4)}, maxLat=${bounds.maxLat.toStringAsFixed(4)}');
    await forceRefresh(bounds);
  }

  Future<void> _executeQuery(MapBounds bounds) async {
    debugPrint('🔍 [PeopleMapDiscovery] _executeQuery iniciado...');
    final quadkey = bounds.toQuadkey();

    if (_shouldUseCache(quadkey)) {
      debugPrint('📦 [PeopleMapDiscovery] Usando cache: ${_cachedPeople.length} pessoas');
      nearbyPeople.value = _cachedPeople;
      nearbyPeopleCount.value = _cachedCount;
      return;
    }

    try {
      // Obter localização atual do usuário para cálculo de distância
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ [PeopleMapDiscovery] Usuário não autenticado');
        return;
      }

      final userLocation = await _locationService.getCurrentLocation();
      if (userLocation == null) {
        debugPrint('⚠️ [PeopleMapDiscovery] Localização do usuário não disponível');
        return;
      }

      // IMPORTANTE: a lista do mapa deve ser determinada pelo BOUNDING BOX,
      // não por um raio fixo (ex.: 30km). Como o PeopleCloudService ainda
      // filtra por radiusKm ao calcular distâncias, aqui calculamos um raio
      // grande o suficiente para cobrir todo o bounding box a partir do usuário.
      final radiusKm = _radiusKmToCoverBoundsFromUser(
        bounds: bounds,
        userLat: userLocation.latitude,
        userLng: userLocation.longitude,
      );

      debugPrint('🔍 [PeopleMapDiscovery] Chamando Cloud Function...');
      debugPrint('   📍 User: (${userLocation.latitude}, ${userLocation.longitude})');
      debugPrint('   📏 Radius: ${radiusKm.toStringAsFixed(1)}km');
      debugPrint('   📐 Bounds: ${bounds.minLat.toStringAsFixed(4)},${bounds.maxLat.toStringAsFixed(4)},${bounds.minLng.toStringAsFixed(4)},${bounds.maxLng.toStringAsFixed(4)}');

      final result = await _cloudService.getPeopleNearby(
        userLatitude: userLocation.latitude,
        userLongitude: userLocation.longitude,
        radiusKm: radiusKm,
        boundingBox: {
          'minLat': bounds.minLat,
          'maxLat': bounds.maxLat,
          'minLng': bounds.minLng,
          'maxLng': bounds.maxLng,
        },
      );

      debugPrint('☁️ [PeopleMapDiscovery] Cloud Function retornou ${result.users.length} usuários');

        // Buscar interesses do usuário atual (cacheado no UserRepository)
        // para calcular commonInterests (matchs) nos cards.
        final myUserData = await _userRepository.getCurrentUserData();
        final myInterests = (myUserData?['interests'] as List?)
            ?.whereType<String>()
            .toList() ??
          const <String>[];

      final currentUserId = currentUser.uid;
      var selfIncludedInPage = false;

      // Converter UserWithDistance para User
      final people = <app_user.User>[];
      for (final uwd in result.users) {
        try {
          final userData = Map<String, dynamic>.from(uwd.userData);

          final candidateId = (userData['userId'] ?? userData['uid'] ?? userData['id'])?.toString();
          if (candidateId != null && candidateId == currentUserId) {
            selfIncludedInPage = true;
            continue;
          }

          userData['distance'] = uwd.distanceKm;

          // Enriquecer com interesses em comum (se possível)
          // (não depende de Firestore por usuário, só usa o payload já retornado)
          final userInterests = (userData['interests'] as List?)
                  ?.whereType<String>()
                  .toList() ??
              const <String>[];
          if (myInterests.isNotEmpty && userInterests.isNotEmpty) {
            userData['commonInterests'] = InterestsHelper.getCommonInterestsList(
              userInterests,
              myInterests,
            );
          } else {
            userData['commonInterests'] = const <String>[];
          }

          final user = app_user.User.fromDocument(userData);
          people.add(user);
          debugPrint('   ✅ Convertido: ${user.userFullname} (${uwd.distanceKm.toStringAsFixed(1)}km)');
        } catch (e) {
          debugPrint('   ❌ Erro ao converter usuário: $e');
        }
      }

      // ✅ Pré-carregar avatares no UserStore para o StableAvatar renderizar sem delay.
      // Mantém o impacto controlado: apenas os primeiros 20 (itens mais prováveis de aparecer).
      final userStore = UserStore.instance;
      final preloadLimit = people.length > 20 ? 20 : people.length;
      for (final user in people.take(preloadLimit)) {
        final photoUrl = user.photoUrl;
        if (photoUrl.isNotEmpty) {
          userStore.preloadAvatar(user.userId, photoUrl);
        }
      }

      final adjustedTotalCandidates = selfIncludedInPage
          ? (result.totalCandidates - 1).clamp(0, 1 << 30)
          : result.totalCandidates;

      _cachedPeople = people;
      _cachedCount = adjustedTotalCandidates;
      _lastFetchTime = DateTime.now();
      _lastQuadkey = quadkey;

      debugPrint('📋 [PeopleMapDiscovery] Atualizando nearbyPeople com ${people.length} pessoas');
      nearbyPeople.value = people;
      nearbyPeopleCount.value = adjustedTotalCandidates;

      debugPrint('✅ [PeopleMapDiscovery] ${people.length} pessoas encontradas (total: $adjustedTotalCandidates)');
    } catch (e, stack) {
      debugPrint('⚠️ [PeopleMapDiscovery] Falha ao buscar pessoas em bounds: $e');
      debugPrint('   Stack: $stack');
    }
  }

  /// Calcula um raio (km) grande o suficiente para cobrir o bounding box
  /// a partir da posição do usuário.
  ///
  /// Motivo: o PeopleCloudService calcula distâncias e filtra por radiusKm.
  /// Para que o bounding box seja a fonte de verdade da lista, precisamos
  /// garantir que radiusKm não exclua usuários que estão dentro do bounds.
  double _radiusKmToCoverBoundsFromUser({
    required MapBounds bounds,
    required double userLat,
    required double userLng,
  }) {
    final corners = <({double lat, double lng})>[
      (lat: bounds.minLat, lng: bounds.minLng),
      (lat: bounds.minLat, lng: bounds.maxLng),
      (lat: bounds.maxLat, lng: bounds.minLng),
      (lat: bounds.maxLat, lng: bounds.maxLng),
    ];

    var maxKm = 0.0;
    for (final c in corners) {
      final d = _haversineKm(
        lat1: userLat,
        lng1: userLng,
        lat2: c.lat,
        lng2: c.lng,
      );
      if (d > maxKm) maxKm = d;
    }

    // Pequena folga para garantir cobertura.
    final radiusKm = maxKm + 1.0;

    // Proteção contra valores absurdos (pan/zoom muito distante).
    // 20.000km cobre praticamente qualquer deslocamento na Terra.
    return radiusKm.clamp(1.0, 20000.0);
  }

  double _haversineKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final rLat1 = _degToRad(lat1);
    final rLat2 = _degToRad(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rLat1) * math.cos(rLat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  void clearCache() {
    _cachedPeople = [];
    _cachedCount = 0;
    _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(0);
    _lastQuadkey = null;
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
