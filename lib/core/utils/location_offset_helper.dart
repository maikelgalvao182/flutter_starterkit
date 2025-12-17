import 'dart:math';

/// Utilitário para gerar offset de localização determinístico
/// 
/// Gera coordenadas display com offset aleatório mas reprodutível
/// para proteger a privacidade do usuário.
class LocationOffsetHelper {
  /// Raio mínimo do offset (em metros)
  static const double minOffsetMeters = 300;
  
  /// Raio máximo do offset (em metros)
  static const double maxOffsetMeters = 1500;
  
  /// Raio da Terra (em km)
  static const double earthRadiusKm = 6371;
  
  /// Gera um número pseudo-aleatório determinístico baseado em uma string seed
  static double _seededRandom(String seed, int index) {
    // Combina seed + index para gerar diferentes valores da mesma seed
    final combined = '$seed-$index';
    
    // Hash simples mas eficaz
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      final char = combined.codeUnitAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    
    // Normaliza para [0, 1]
    final normalized = hash.abs() / 2147483647;
    return normalized;
  }
  
  /// Calcula coordenadas display com offset determinístico
  /// 
  /// Regras:
  /// - Offset mínimo: 300 metros
  /// - Offset máximo: 1500 metros (1.5 km)
  /// - Direção aleatória mas fixa por userId
  /// - Reprodutível (mesmo input = mesmo output)
  static Map<String, double> generateDisplayLocation({
    required double realLat,
    required double realLng,
    required String userId,
  }) {
    // Gera valores determinísticos baseados no userId
    final random1 = _seededRandom(userId, 0); // Para distância
    final random2 = _seededRandom(userId, 1); // Para ângulo
    
    // Calcula distância do offset (entre 300m e 1500m)
    final offsetMeters = minOffsetMeters + (random1 * (maxOffsetMeters - minOffsetMeters));
    final offsetKm = offsetMeters / 1000;
    
    // Calcula ângulo aleatório (0 a 360 graus)
    final angle = random2 * 2 * pi;
    
    // Converte offset para graus
    // 1 grau de latitude ≈ 111 km
    // 1 grau de longitude varia com a latitude
    final latOffset = (offsetKm / earthRadiusKm) * (180 / pi);
    final lngOffset = (offsetKm / earthRadiusKm) * (180 / pi) / cos(realLat * pi / 180);
    
    // Aplica offset na direção do ângulo
    final displayLatitude = realLat + (latOffset * cos(angle));
    final displayLongitude = realLng + (lngOffset * sin(angle));
    
    return {
      'displayLatitude': displayLatitude,
      'displayLongitude': displayLongitude,
    };
  }
}
