import 'package:partiu/core/utils/geo_distance_helper.dart';

/// Helper para cálculos puros relacionados a interesses e distâncias
/// 
/// NÃO faz queries ao Firestore - apenas cálculos em memória
/// Para buscar dados, use UserRepository
class InterestsHelper {
  /// Calcula interesses em comum entre duas listas de interesses
  /// Retorna a porcentagem de interesses em comum (0.0 a 1.0)
  static double calculateCommonInterests(
    List<String> userInterests,
    List<String> myInterests,
  ) {
    if (userInterests.isEmpty || myInterests.isEmpty) return 0.0;
    
    final common = userInterests.toSet().intersection(myInterests.toSet());
    return common.length / userInterests.length;
  }
  
  /// Retorna lista de interesses em comum
  static List<String> getCommonInterestsList(
    List<String> userInterests,
    List<String> myInterests,
  ) {
    return userInterests.toSet().intersection(myInterests.toSet()).toList();
  }

  /// Calcula distância em km entre dois usuários
  /// 
  /// 🔒 USA COORDENADAS DISPLAY (com offset de privacidade)
  /// Requer dados completos de ambos os usuários (displayLatitude e displayLongitude)
  /// 
  /// Fallback: se displayLatitude/displayLongitude não existirem, usa latitude/longitude
  static double? calculateDistance(
    Map<String, dynamic> userData1,
    Map<String, dynamic> userData2,
  ) {
    // Prioriza coordenadas display (com offset de privacidade)
    final lat1 = (userData1['displayLatitude'] as num?)?.toDouble() ?? 
                 (userData1['latitude'] as num?)?.toDouble();
    final lng1 = (userData1['displayLongitude'] as num?)?.toDouble() ?? 
                 (userData1['longitude'] as num?)?.toDouble();
    final lat2 = (userData2['displayLatitude'] as num?)?.toDouble() ?? 
                 (userData2['latitude'] as num?)?.toDouble();
    final lng2 = (userData2['displayLongitude'] as num?)?.toDouble() ?? 
                 (userData2['longitude'] as num?)?.toDouble();

    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return null;
    }

    return GeoDistanceHelper.distanceInKm(lat1, lng1, lat2, lng2);
  }

  /// Enriquece dados de um usuário com interesses em comum e distância
  /// 
  /// Modifica o Map passado por referência, adicionando:
  /// - commonInterests: List<String>
  /// - distance: double?
  static void enrichUserData({
    required Map<String, dynamic> userData,
    required List<String> myInterests,
    Map<String, dynamic>? myUserData,
  }) {
    // Adicionar interesses em comum
    final userInterests = List<String>.from(userData['interests'] ?? []);
    userData['commonInterests'] = getCommonInterestsList(userInterests, myInterests);

    // Adicionar distância se dados de localização disponíveis
    if (myUserData != null) {
      final distance = calculateDistance(myUserData, userData);
      if (distance != null) {
        userData['distance'] = distance;
      }
    }
  }
}
