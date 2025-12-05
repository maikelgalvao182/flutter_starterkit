import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:partiu/core/utils/geo_distance_helper.dart';
import 'dart:math' show cos;

class GeoService {
  // Singleton
  static final GeoService _instance = GeoService._internal();
  factory GeoService() => _instance;
  GeoService._internal();

  /// Obtém a localização atual do usuário logado (do Firestore)
  Future<({double lat, double lng})?> getCurrentUserLocation() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    try {
      // Buscar da coleção Users (onde estão os dados completos)
      var doc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        return (lat: lat, lng: lng);
      }
    } catch (e) {
      // Silently fail or log error
      print('Erro ao buscar localização do usuário: $e');
    }
    return null;
  }

  /// Calcula a distância entre o usuário atual e um alvo
  Future<double?> getDistanceToTarget({
    required double targetLat,
    required double targetLng,
  }) async {
    final currentLocation = await getCurrentUserLocation();

    if (currentLocation == null) return null;

    return GeoDistanceHelper.distanceInKm(
      currentLocation.lat,
      currentLocation.lng,
      targetLat,
      targetLng,
    );
  }

  /// Helper para criar bounding box
  ({double minLat, double maxLat, double minLng, double maxLng}) _buildBoundingBox(
      double lat, double lng, double radiusKm) {
    const earthRadiusKm = 6371;

    final latDelta = radiusKm / earthRadiusKm * (180 / 3.141592653589793);
    final lngDelta = radiusKm /
        (earthRadiusKm * (cos(lat * 3.141592653589793 / 180))) *
        (180 / 3.141592653589793);

    return (
      minLat: lat - latDelta,
      maxLat: lat + latDelta,
      minLng: lng - lngDelta,
      maxLng: lng + lngDelta,
    );
  }

  /// Método profissional para listar até 100 perfis num raio de 30km
  Future<List<Map<String, dynamic>>> getUsersWithin30Km({
    required double lat,
    required double lng,
    int limit = 100,
  }) async {
    try {
      final box = _buildBoundingBox(lat, lng, 30);

      // Tenta buscar na coleção 'Users' (padrão do app)
      // Nota: O app tem inconsistências entre 'Users' e 'users'. 
      // UserRepository usa 'Users', então priorizamos 'Users'.
      
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('latitude', isGreaterThan: box.minLat)
          .where('latitude', isLessThan: box.maxLat)
          .limit(300) // Pega um pouco mais para filtrar longitude e distância no cliente
          .get();

      List<Map<String, dynamic>> results = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final userLat = (data['latitude'] as num?)?.toDouble();
        final userLng = (data['longitude'] as num?)?.toDouble();

        if (userLat == null || userLng == null) continue;
        
        // Filtra longitude no cliente
        if (userLng < box.minLng || userLng > box.maxLng) continue;

        final d = GeoDistanceHelper.distanceInKm(lat, lng, userLat, userLng);

        if (d <= 30) {
          results.add({
            'id': doc.id,
            'data': data,
            'distance': d,
          });
        }
      }

      // Ordena por distância real
      results.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      // Retorna só os mais próximos
      return results.take(limit).toList();
    } catch (e) {
      print("Erro em getUsersWithin30Km: $e");
      return [];
    }
  }

  /// Conta quantos usuários estão num raio de 30km
  Future<int> countUsersWithin30Km(double lat, double lng) async {
    final users = await getUsersWithin30Km(lat: lat, lng: lng);
    return users.length;
  }
}
