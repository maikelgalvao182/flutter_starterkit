import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:partiu/core/services/location_service.dart';
import 'package:partiu/core/services/location_permission_flow.dart';
import 'package:partiu/core/services/location_analytics_service.dart';

/// Configuração para o LocationSyncScheduler
/// 
/// Permite configurar thresholds dinamicamente sem recompilar
class LocationConfig {
  /// Intervalo entre atualizações automáticas
  final Duration updateInterval;
  
  /// Distância mínima (em metros) para disparar atualização
  final double minimumDistanceMeters;
  
  /// Idade máxima do cache (em minutos)
  final int cacheMaxAgeMinutes;
  
  const LocationConfig({
    this.updateInterval = const Duration(minutes: 10),
    this.minimumDistanceMeters = 100.0,
    this.cacheMaxAgeMinutes = 15,
  });
  
  /// Configuração padrão recomendada (Uber/Tinder)
  static const LocationConfig standard = LocationConfig();
  
  /// Configuração agressiva (mais atualizações, maior precisão)
  static const LocationConfig aggressive = LocationConfig(
    updateInterval: Duration(minutes: 5),
    minimumDistanceMeters: 50.0,
    cacheMaxAgeMinutes: 10,
  );
  
  /// Configuração econômica (menos atualizações, economia de bateria)
  static const LocationConfig economy = LocationConfig(
    updateInterval: Duration(minutes: 30),
    minimumDistanceMeters: 500.0,
    cacheMaxAgeMinutes: 30,
  );
}

/// Serviço que sincroniza automaticamente a localização do usuário no Firestore
/// 
/// Responsabilidades:
/// - Rodar periodicamente (a cada X minutos)
/// - Verificar permissões antes de obter localização
/// - Atualizar apenas se a distância mudou significativamente (debounce espacial)
/// - Salvar coordenadas no documento do usuário no Firestore
/// - Evitar writes desnecessários (economia de bateria e Firestore)
/// 
/// Padrão usado por: Uber, Tinder, WhatsApp, iFood
class LocationSyncScheduler {
  
  static Timer? _timer;
  static Position? _lastSavedPosition;
  static LocationConfig _config = LocationConfig.standard;

  /// Inicia o sincronizador automático de localização
  /// 
  /// Parâmetros:
  /// - `locationService`: instância do LocationService para obter coordenadas
  /// - `config`: configuração de thresholds (padrão: LocationConfig.standard)
  static void start(
    LocationService locationService, {
    LocationConfig config = LocationConfig.standard,
  }) {
    _config = config;
    // Cancela timer anterior se existir
    _timer?.cancel();

    debugPrint('🔄 LocationSyncScheduler iniciado (intervalo: ${config.updateInterval})');
    debugPrint('📍 Configuração: distância mínima=${config.minimumDistanceMeters}m, cache=${config.cacheMaxAgeMinutes}min');

    // Executa imediatamente na primeira vez
    _updateLocationIfNeeded(locationService);

    // Configura timer periódico
    _timer = Timer.periodic(config.updateInterval, (_) {
      _updateLocationIfNeeded(locationService);
    });
  }

  /// Para o sincronizador automático
  static void stop() {
    _timer?.cancel();
    _timer = null;
    debugPrint('🛑 LocationSyncScheduler parado');
  }
  
  /// Retorna a configuração atual
  static LocationConfig get config => _config;

  /// Lógica interna: atualiza localização apenas se necessário
  static Future<void> _updateLocationIfNeeded(
    LocationService locationService,
  ) async {
    try {
      // 1. Verifica se usuário está autenticado
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ Usuário não autenticado - pulando atualização de localização');
        return;
      }

      // 2. Verifica permissões
      final permissionFlow = LocationPermissionFlow();
      final permission = await permissionFlow.check();

      if (!permissionFlow.isPermissionGranted(permission)) {
        debugPrint('⚠️ Permissão de localização não concedida - pulando atualização');
        return;
      }

      // 3. Obtém localização atual
      final position = await locationService.getCurrentLocation(
        timeout: const Duration(seconds: 8),
      );

      if (position == null) {
        debugPrint('⚠️ Não foi possível obter localização - pulando atualização');
        return;
      }

      // 4. Verifica se vale a pena atualizar (debounce espacial)
      if (!_shouldUpdateFirestore(position)) {
        debugPrint('ℹ️ Usuário não se moveu o suficiente - pulando atualização');
        return;
      }

      // 5. Atualiza Firestore
      await _saveLocationToFirestore(
        userId: user.uid,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // 6. Atualiza referência da última posição salva
      _lastSavedPosition = position;

      debugPrint('✅ Localização atualizada no Firestore: ${position.latitude}, ${position.longitude}');

    } catch (e) {
      debugPrint('❌ Erro ao atualizar localização em background: $e');
    }
  }

  /// Verifica se a nova posição está distante o suficiente da última salva
  static bool _shouldUpdateFirestore(Position newPosition) {
    if (_lastSavedPosition == null) return true;

    final distance = Geolocator.distanceBetween(
      _lastSavedPosition!.latitude,
      _lastSavedPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    final threshold = _config.minimumDistanceMeters;

    // Log analytics se movimento for significativo
    if (distance > threshold) {
      LocationAnalyticsService.instance.logSignificantMovement(
        distanceMeters: distance,
        threshold: threshold,
      );
    }

    return distance > threshold;
  }

  /// Salva localização no documento do usuário no Firestore
  static Future<void> _saveLocationToFirestore({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update({
        'latitude': latitude,
        'longitude': longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Erro ao salvar localização no Firestore: $e');
      rethrow;
    }
  }

  /// Força uma atualização imediata (útil após login ou mudança manual de localização)
  static Future<void> forceUpdate(LocationService locationService) async {
    debugPrint('⚡ Forçando atualização imediata de localização');
    _lastSavedPosition = null; // Reseta para garantir que vai salvar
    await _updateLocationIfNeeded(locationService);
  }

  /// Retorna se o updater está ativo
  static bool get isActive => _timer != null && _timer!.isActive;
}
