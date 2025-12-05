import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/data/models/pending_application_model.dart';

/// Repository para buscar aplicações pendentes dos eventos do usuário
class PendingApplicationsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PendingApplicationsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Stream de aplicações pendentes para eventos criados pelo usuário atual
  /// 
  /// Retorna stream que emite lista de PendingApplicationModel sempre que houver mudança
  Stream<List<PendingApplicationModel>> getPendingApplicationsStream() {
    final userId = _auth.currentUser?.uid;
    debugPrint('📡 PendingApplicationsRepository: Iniciando stream');
    debugPrint('   - userId atual: $userId');
    
    if (userId == null) {
      debugPrint('   ❌ Usuário não autenticado, retornando stream vazio');
      return Stream.value([]);
    }

    // 1. Stream de eventos do usuário
    return _firestore
        .collection('events')
        .where('createdBy', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .where('isCanceled', isEqualTo: false)
        .snapshots()
        .asyncMap((eventsSnapshot) async {
      debugPrint('📋 PendingApplicationsRepository: Eventos recebidos');
      debugPrint('   - Total de eventos: ${eventsSnapshot.docs.length}');
      
      if (eventsSnapshot.docs.isEmpty) {
        debugPrint('   ⚠️ Nenhum evento encontrado para o usuário');
        return <PendingApplicationModel>[];
      }

      final eventIds = eventsSnapshot.docs.map((doc) => doc.id).toList();
      debugPrint('   - EventIds: ${eventIds.join(", ")}');

      // 2. Buscar aplicações pendentes para esses eventos
      debugPrint('🔍 Buscando aplicações pendentes...');
      final applicationsSnapshot = await _firestore
          .collection('EventApplications')
          .where('eventId', whereIn: eventIds)
          .where('status', isEqualTo: 'pending')
          .orderBy('appliedAt', descending: true)
          .get();

      debugPrint('   - Aplicações pendentes encontradas: ${applicationsSnapshot.docs.length}');
      
      if (applicationsSnapshot.docs.isEmpty) {
        debugPrint('   ℹ️ Nenhuma aplicação pendente para esses eventos');
        return <PendingApplicationModel>[];
      }

      // Log de cada aplicação
      for (var i = 0; i < applicationsSnapshot.docs.length; i++) {
        final doc = applicationsSnapshot.docs[i];
        debugPrint('   [$i] applicationId: ${doc.id}');
        debugPrint('       eventId: ${doc.data()['eventId']}');
        debugPrint('       userId: ${doc.data()['userId']}');
        debugPrint('       status: ${doc.data()['status']}');
        debugPrint('       appliedAt: ${doc.data()['appliedAt']}');
      }

      // 3. Extrair userIds únicos
      final userIds = applicationsSnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toSet()
          .toList();
      
      debugPrint('👥 Buscando dados de ${userIds.length} usuários...');

      // 4. Buscar dados dos usuários em batch
      final usersSnapshot = await _firestore
          .collection('Users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      debugPrint('   - Usuários encontrados: ${usersSnapshot.docs.length}');

      // 5. Criar map userId -> userData
      final usersMap = {
        for (var doc in usersSnapshot.docs) doc.id: doc.data()
      };

      // 6. Criar map eventId -> eventData
      final eventsMap = {
        for (var doc in eventsSnapshot.docs) doc.id: doc.data()
      };

      // 7. Combinar dados e criar models
      final pendingApplications = <PendingApplicationModel>[];
      
      debugPrint('🔨 Combinando dados...');

      for (final appDoc in applicationsSnapshot.docs) {
        final appData = appDoc.data();
        final userId = appData['userId'] as String;
        final eventId = appData['eventId'] as String;

        final userData = usersMap[userId];
        final eventData = eventsMap[eventId];

        debugPrint('   - Processando applicationId: ${appDoc.id}');
        debugPrint('     userData presente: ${userData != null}');
        debugPrint('     eventData presente: ${eventData != null}');

        if (userData != null && eventData != null) {
          try {
            final model = PendingApplicationModel.fromCombined(
              applicationId: appDoc.id,
              applicationData: appData,
              userData: userData,
              eventData: eventData,
            );
            pendingApplications.add(model);
            debugPrint('     ✅ Model criado: ${model.userFullName} -> ${model.activityText}');
          } catch (e) {
            debugPrint('     ❌ Erro ao criar PendingApplicationModel: $e');
          }
        } else {
          debugPrint('     ⚠️ Dados faltando, pulando...');
        }
      }

      debugPrint('✅ Total de aplicações processadas: ${pendingApplications.length}');
      return pendingApplications;
    });
  }
}
