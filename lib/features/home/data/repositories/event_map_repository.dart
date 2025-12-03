import 'dart:math' as math;
import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partiu/features/home/data/models/event_model.dart';

/// Repositório para buscar eventos próximos no mapa
class EventMapRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca eventos dentro de um raio da localização do usuário
  /// 
  /// Parâmetros:
  /// - [userLocation]: Localização atual do usuário
  /// - [radiusKm]: Raio de busca em quilômetros (padrão: 10km)
  Future<List<EventModel>> getEventsWithinRadius(
    LatLng userLocation, {
    double radiusKm = 10.0,
  }) async {
    try {
      debugPrint('📍 [EventMapRepository] Buscando eventos próximos...');

      // Buscar eventos ativos
      final snapshot = await _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      final events = <EventModel>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final location = data['location'] as Map<String, dynamic>?;

          if (location == null) continue;

          final lat = (location['latitude'] as num?)?.toDouble();
          final lng = (location['longitude'] as num?)?.toDouble();

          if (lat == null || lng == null) continue;

          // Calcular distância
          final distance = _calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            lat,
            lng,
          );

          // Filtrar por raio
          if (distance <= radiusKm) {
            final event = EventModel(
              id: doc.id,
              emoji: data['emoji'] as String? ?? '🎉',
              createdBy: data['createdBy'] as String? ?? '',
              lat: lat,
              lng: lng,
              title: data['activityText'] as String? ?? '',
            );
            events.add(event);
          }
        } catch (e) {
          debugPrint('⚠️ Erro ao processar evento ${doc.id}: $e');
        }
      }

      debugPrint('✅ [EventMapRepository] ${events.length} eventos encontrados');
      return events;
    } catch (e) {
      debugPrint('❌ [EventMapRepository] Erro ao buscar eventos: $e');
      return [];
    }
  }

  /// Calcula distância entre dois pontos em km usando fórmula de Haversine
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
