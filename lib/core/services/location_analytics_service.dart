import 'package:flutter/foundation.dart';

/// Eventos de analytics para localização
/// 
/// Usado para rastrear comportamento do usuário relacionado a localização
enum LocationAnalyticsEvent {
  /// Permissão de localização concedida
  permissionGranted,
  
  /// Permissão de localização negada
  permissionDenied,
  
  /// Permissão de localização negada permanentemente
  permissionDeniedForever,
  
  /// GPS está desligado
  gpsDisabled,
  
  /// Localização atualizada com sucesso
  locationUpdated,
  
  /// Usuário se moveu mais que o threshold
  significantMovement,
  
  /// Falha ao obter localização
  locationError,
  
  /// Timeout ao obter localização
  locationTimeout,
  
  /// Usou localização em cache
  usedCachedLocation,
  
  /// Usou fallback de baixa precisão
  usedLowAccuracyFallback,
}

/// Serviço de analytics para eventos de localização
/// 
/// Registra eventos importantes para análise de comportamento
/// e troubleshooting de problemas de localização
class LocationAnalyticsService {
  LocationAnalyticsService._();
  
  static final LocationAnalyticsService instance = LocationAnalyticsService._();
  
  /// Registra um evento de localização
  void logEvent(
    LocationAnalyticsEvent event, {
    Map<String, dynamic>? parameters,
  }) {
    final eventName = _getEventName(event);
    
    // TODO: Integrar com Firebase Analytics ou outro provider
    // FirebaseAnalytics.instance.logEvent(
    //   name: eventName,
    //   parameters: parameters,
    // );
    
    // Por enquanto apenas log de debug
    debugPrint('📊 LocationAnalytics: $eventName ${parameters ?? ""}');
  }
  
  /// Registra permissão concedida
  void logPermissionGranted() {
    logEvent(LocationAnalyticsEvent.permissionGranted);
  }
  
  /// Registra permissão negada
  void logPermissionDenied() {
    logEvent(LocationAnalyticsEvent.permissionDenied);
  }
  
  /// Registra permissão negada permanentemente
  void logPermissionDeniedForever() {
    logEvent(LocationAnalyticsEvent.permissionDeniedForever);
  }
  
  /// Registra GPS desligado
  void logGpsDisabled() {
    logEvent(LocationAnalyticsEvent.gpsDisabled);
  }
  
  /// Registra localização atualizada
  void logLocationUpdated({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) {
    logEvent(
      LocationAnalyticsEvent.locationUpdated,
      parameters: {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      },
    );
  }
  
  /// Registra movimento significativo
  void logSignificantMovement({
    required double distanceMeters,
    required double threshold,
  }) {
    logEvent(
      LocationAnalyticsEvent.significantMovement,
      parameters: {
        'distance_meters': distanceMeters,
        'threshold_meters': threshold,
      },
    );
  }
  
  /// Registra erro de localização
  void logLocationError(String error) {
    logEvent(
      LocationAnalyticsEvent.locationError,
      parameters: {'error': error},
    );
  }
  
  /// Registra timeout de localização
  void logLocationTimeout(int seconds) {
    logEvent(
      LocationAnalyticsEvent.locationTimeout,
      parameters: {'timeout_seconds': seconds},
    );
  }
  
  /// Registra uso de cache
  void logUsedCache({required int cacheAgeMinutes}) {
    logEvent(
      LocationAnalyticsEvent.usedCachedLocation,
      parameters: {'cache_age_minutes': cacheAgeMinutes},
    );
  }
  
  /// Registra uso de fallback de baixa precisão
  void logUsedLowAccuracyFallback() {
    logEvent(LocationAnalyticsEvent.usedLowAccuracyFallback);
  }
  
  /// Converte enum para nome de evento
  String _getEventName(LocationAnalyticsEvent event) {
    switch (event) {
      case LocationAnalyticsEvent.permissionGranted:
        return 'location_permission_granted';
      case LocationAnalyticsEvent.permissionDenied:
        return 'location_permission_denied';
      case LocationAnalyticsEvent.permissionDeniedForever:
        return 'location_permission_denied_forever';
      case LocationAnalyticsEvent.gpsDisabled:
        return 'location_gps_disabled';
      case LocationAnalyticsEvent.locationUpdated:
        return 'location_updated';
      case LocationAnalyticsEvent.significantMovement:
        return 'location_significant_movement';
      case LocationAnalyticsEvent.locationError:
        return 'location_error';
      case LocationAnalyticsEvent.locationTimeout:
        return 'location_timeout';
      case LocationAnalyticsEvent.usedCachedLocation:
        return 'location_used_cache';
      case LocationAnalyticsEvent.usedLowAccuracyFallback:
        return 'location_used_fallback';
    }
  }
}
