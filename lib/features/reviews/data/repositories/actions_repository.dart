import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/shared/repositories/user_repository.dart';

/// Repository para enriquecer dados de ações pendentes (aplicações e reviews)
/// 
/// Responsável por buscar dados complementares de usuários e eventos
class ActionsRepository {
  final FirebaseFirestore _firestore;
  final UserRepository _userRepo;

  ActionsRepository({
    FirebaseFirestore? firestore,
    UserRepository? userRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _userRepo = userRepository ?? UserRepository(firestore);

  /// Busca dados do criador de um evento (owner)
  /// 
  /// Retorna Map com userId, fullName e photoUrl do criador
  Future<Map<String, dynamic>?> getEventOwnerData(String eventId) async {
    try {
      debugPrint('🔍 ActionsRepository: Buscando owner do evento $eventId');
      
      // 1. Buscar evento
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      
      if (!eventDoc.exists) {
        debugPrint('⚠️ ActionsRepository: Evento $eventId não encontrado');
        return null;
      }
      
      final eventData = eventDoc.data()!;
      final ownerId = eventData['createdBy'] as String?;
      
      if (ownerId == null || ownerId.isEmpty) {
        debugPrint('⚠️ ActionsRepository: Evento $eventId sem createdBy');
        return null;
      }
      
      debugPrint('🔍 ActionsRepository: Owner ID encontrado: $ownerId');
      
      // 2. Buscar dados do usuário
      final userData = await _userRepo.getUserBasicInfo(ownerId);
      
      if (userData == null) {
        debugPrint('⚠️ ActionsRepository: Dados do owner $ownerId não encontrados');
        return {
          'userId': ownerId,
          'fullName': 'Usuário',
          'photoUrl': null,
        };
      }
      
      debugPrint('✅ ActionsRepository: Dados do owner carregados: ${userData['fullName']}');
      
      return {
        'userId': userData['userId'],
        'fullName': userData['fullName'],
        'photoUrl': userData['photoUrl'],
      };
    } catch (e) {
      debugPrint('❌ ActionsRepository: Erro ao buscar owner do evento $eventId: $e');
      return null;
    }
  }

  /// Busca dados de múltiplos owners em batch
  /// 
  /// Recebe Map<eventId, PendingReview> e retorna Map<eventId, ownerData>
  Future<Map<String, Map<String, dynamic>>> getMultipleEventOwnersData(
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) return {};

    try {
      debugPrint('🔍 ActionsRepository: Buscando owners de ${eventIds.length} eventos');
      
      final results = <String, Map<String, dynamic>>{};
      
      // 1. Buscar eventos em batch (máx 10 por query)
      for (var i = 0; i < eventIds.length; i += 10) {
        final chunk = eventIds.skip(i).take(10).toList();
        
        final eventsSnapshot = await _firestore
            .collection('events')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        // 2. Coletar owner IDs
        final ownerIds = <String>{};
        final eventToOwner = <String, String>{};
        
        for (final doc in eventsSnapshot.docs) {
          final ownerId = doc.data()['createdBy'] as String?;
          if (ownerId != null && ownerId.isNotEmpty) {
            ownerIds.add(ownerId);
            eventToOwner[doc.id] = ownerId;
          }
        }
        
        // 3. Buscar dados dos owners
        if (ownerIds.isNotEmpty) {
          final usersData = await _userRepo.getUsersByIds(ownerIds.toList());
          
          // 4. Mapear eventos para dados dos owners
          for (final eventId in chunk) {
            final ownerId = eventToOwner[eventId];
            if (ownerId != null) {
              final userData = usersData[ownerId];
              if (userData != null) {
                results[eventId] = {
                  'userId': ownerId,
                  'fullName': userData['fullName'] ?? 'Usuário',
                  'photoUrl': userData['photoUrl'],
                };
              }
            }
          }
        }
      }
      
      debugPrint('✅ ActionsRepository: ${results.length} owners carregados');
      
      return results;
    } catch (e) {
      debugPrint('❌ ActionsRepository: Erro ao buscar owners: $e');
      return {};
    }
  }
}
