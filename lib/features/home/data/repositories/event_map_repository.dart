import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partiu/features/home/data/models/event_model.dart';

/// Repositório para buscar eventos próximos no mapa
class EventMapRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca eventos ativos próximos à localização do usuário
  /// 
  /// Parâmetros:
  /// - [userLocation]: Localização atual do usuário
  /// 
  /// NOTA: Este método NÃO aplica filtro de raio.
  /// Retorna TODOS os eventos ativos e NÃO cancelados.
  /// A distância/disponibilidade são calculadas posteriormente pelo MapViewModel.
  Future<List<EventModel>> getEventsWithinRadius(
    LatLng userLocation,
  ) async {
    try {
      debugPrint('📍 [EventMapRepository] Buscando eventos próximos...');

      // Buscar eventos ativos e não cancelados
      final snapshot = await _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      final events = <EventModel>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          // Filtrar eventos cancelados (dupla checagem no cliente)
          final isCanceled = data['isCanceled'] as bool? ?? false;
          if (isCanceled) {
            debugPrint('⏭️ Evento ${doc.id} está cancelado, pulando...');
            continue;
          }

          final location = data['location'] as Map<String, dynamic>?;

          if (location == null) continue;

          final lat = (location['latitude'] as num?)?.toDouble();
          final lng = (location['longitude'] as num?)?.toDouble();

          if (lat == null || lng == null) continue;

          // Extrair dados adicionais para pré-carregar no EventCard
          final participantsData = data['participants'] as Map<String, dynamic>?;
          final scheduleData = data['schedule'] as Map<String, dynamic>?;
          final dateTimestamp = scheduleData?['date'] as Timestamp?;
          
          // Parse photoReferences
          List<String>? photoReferences;
          final photoRefs = location['photoReferences'] as List<dynamic>?;
          if (photoRefs != null) {
            photoReferences = photoRefs.map((e) => e.toString()).toList();
          }

          // Criar evento com TODOS os campos disponíveis
          // A distância/disponibilidade/userApplication serão enriquecidos pelo MapViewModel._enrichEvents()
          final event = EventModel(
            id: doc.id,
            emoji: data['emoji'] as String? ?? '🎉',
            createdBy: data['createdBy'] as String? ?? '',
            lat: lat,
            lng: lng,
            title: data['activityText'] as String? ?? '',
            locationName: location['locationName'] as String?,
            formattedAddress: location['formattedAddress'] as String?,
            placeId: location['placeId'] as String?,
            photoReferences: photoReferences,
            scheduleDate: dateTimestamp?.toDate(),
            privacyType: participantsData?['privacyType'] as String?,
          );
          events.add(event);
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

  /// Busca um evento específico pelo ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data();
      if (data == null) return null;

      final location = data['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final lat = (location['latitude'] as num?)?.toDouble();
      final lng = (location['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) return null;

      final participantsData = data['participants'] as Map<String, dynamic>?;
      final scheduleData = data['schedule'] as Map<String, dynamic>?;
      final dateTimestamp = scheduleData?['date'] as Timestamp?;
      
      List<String>? photoReferences;
      final photoRefs = location['photoReferences'] as List<dynamic>?;
      if (photoRefs != null) {
        photoReferences = photoRefs.map((e) => e.toString()).toList();
      }

      return EventModel(
        id: doc.id,
        emoji: data['emoji'] as String? ?? '🎉',
        createdBy: data['createdBy'] as String? ?? '',
        lat: lat,
        lng: lng,
        title: data['activityText'] as String? ?? '',
        locationName: location['locationName'] as String?,
        formattedAddress: location['formattedAddress'] as String?,
        placeId: location['placeId'] as String?,
        photoReferences: photoReferences,
        scheduleDate: dateTimestamp?.toDate(),
        privacyType: participantsData?['privacyType'] as String?,
      );
    } catch (e) {
      debugPrint('❌ [EventMapRepository] Erro ao buscar evento por ID: $e');
      return null;
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
