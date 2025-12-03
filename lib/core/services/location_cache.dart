import 'package:geolocator/geolocator.dart';

/// Cache singleton para armazenar a última localização conhecida
/// 
/// Benefícios:
/// - Acesso instantâneo sem esperar GPS
/// - Reduz chamadas ao Geolocator
/// - Melhora performance do app
/// - Usado como fallback quando GPS está lento
class LocationCache {
  LocationCache._();
  
  static final LocationCache instance = LocationCache._();
  
  /// Última posição GPS conhecida
  Position? _lastPosition;
  
  /// Timestamp da última atualização
  DateTime? _lastUpdatedAt;
  
  /// Getter para última posição
  Position? get lastPosition => _lastPosition;
  
  /// Getter para timestamp da última atualização
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  
  /// Verifica se o cache é válido (não expirado)
  /// 
  /// Cache expira após [maxAge] minutos
  bool isValid({Duration maxAge = const Duration(minutes: 15)}) {
    if (_lastPosition == null || _lastUpdatedAt == null) {
      return false;
    }
    
    final age = DateTime.now().difference(_lastUpdatedAt!);
    return age < maxAge;
  }
  
  /// Atualiza o cache com nova posição
  void update(Position position) {
    _lastPosition = position;
    _lastUpdatedAt = DateTime.now();
  }
  
  /// Limpa o cache
  void clear() {
    _lastPosition = null;
    _lastUpdatedAt = null;
  }
  
  /// Retorna coordenadas formatadas ou null
  String? getFormattedCoordinates() {
    if (_lastPosition == null) return null;
    
    return '${_lastPosition!.latitude.toStringAsFixed(6)}, '
           '${_lastPosition!.longitude.toStringAsFixed(6)}';
  }
  
  /// Retorna idade do cache em minutos
  int? getCacheAgeMinutes() {
    if (_lastUpdatedAt == null) return null;
    
    return DateTime.now().difference(_lastUpdatedAt!).inMinutes;
  }
}
