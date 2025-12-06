import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/common/state/app_state.dart';

/// Modelo de visita ao perfil
class ProfileVisit {
  final String visitorId;
  final DateTime visitedAt;
  final String? source;
  final int visitCount;

  const ProfileVisit({
    required this.visitorId,
    required this.visitedAt,
    this.source,
    this.visitCount = 1,
  });

  factory ProfileVisit.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileVisit(
      visitorId: data['visitorId'] as String,
      visitedAt: (data['visitedAt'] as Timestamp).toDate(),
      source: data['source'] as String?,
      visitCount: data['visitCount'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitorId': visitorId,
      'visitedAt': Timestamp.fromDate(visitedAt),
      'source': source,
      'visitCount': visitCount,
    };
  }
}

/// Serviço para gerenciar visitas ao perfil
/// 
/// Features:
/// - Registro de visitas com anti-spam
/// - Stream em tempo real
/// - Contador de visitas
/// - TTL automático (7 dias)
/// - Sem duplicatas
class ProfileVisitsService {
  ProfileVisitsService._();
  
  static final ProfileVisitsService _instance = ProfileVisitsService._();
  static ProfileVisitsService get instance => _instance;

  final _firestore = FirebaseFirestore.instance;
  
  // Cache local para anti-spam
  final Map<String, DateTime> _lastVisitCache = {};
  
  // Intervalo mínimo entre visitas (anti-spam)
  static const _minVisitInterval = Duration(minutes: 15);
  
  // TTL para limpeza automática
  static const _visitTTL = Duration(days: 7);

  /// Registra uma visita ao perfil
  /// 
  /// Anti-spam: Só registra se passaram 15 minutos desde a última visita
  /// TTL: Visita expira após 7 dias automaticamente
  Future<void> recordVisit({
    required String visitedUserId,
    String? source,
  }) async {
    final visitorId = AppState.currentUserId;
    if (visitorId == null || visitorId.isEmpty) {
      debugPrint('⚠️ [ProfileVisitsService] Usuário não autenticado');
      return;
    }

    // Não registrar visita ao próprio perfil
    if (visitorId == visitedUserId) {
      debugPrint('⚠️ [ProfileVisitsService] Não registra visita ao próprio perfil');
      return;
    }

    // Anti-spam: Verificar última visita
    final cacheKey = '${visitorId}_$visitedUserId';
    final lastVisit = _lastVisitCache[cacheKey];
    if (lastVisit != null) {
      final diff = DateTime.now().difference(lastVisit);
      if (diff < _minVisitInterval) {
        debugPrint('⏭️ [ProfileVisitsService] Visita muito recente, ignorando (${diff.inMinutes}min)');
        return;
      }
    }

    try {
      final now = DateTime.now();
      final expireAt = now.add(_visitTTL);
      
      // ID do documento: {visitedUserId}_{visitorId} (evita duplicatas)
      final docId = '${visitedUserId}_$visitorId';
      final docRef = _firestore
          .collection('ProfileVisits')
          .doc(docId);

      // Merge: Atualiza se já existe, cria se não existe
      await docRef.set({
        'visitedUserId': visitedUserId,
        'visitorId': visitorId,
        'visitedAt': FieldValue.serverTimestamp(),
        'source': source ?? 'profile',
        'expireAt': Timestamp.fromDate(expireAt),
        'visitCount': FieldValue.increment(1), // Incrementa contador
      }, SetOptions(merge: true));

      // Atualizar cache local
      _lastVisitCache[cacheKey] = now;
      
      debugPrint('✅ [ProfileVisitsService] Visita registrada: $visitorId -> $visitedUserId');
    } catch (e) {
      debugPrint('❌ [ProfileVisitsService] Erro ao registrar visita: $e');
    }
  }

  /// Stream de visitas ao perfil do usuário atual
  /// 
  /// Retorna lista ordenada por data (mais recentes primeiro)
  Stream<List<ProfileVisit>> watchVisits(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('ProfileVisits')
        .where('visitedUserId', isEqualTo: userId)
        .orderBy('visitedAt', descending: true)
        .limit(50) // Limite de 50 visitas mais recentes
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProfileVisit.fromDoc(doc))
              .toList();
        })
        .handleError((error) {
          debugPrint('❌ [ProfileVisitsService] Erro no stream: $error');
          return <ProfileVisit>[];
        });
  }

  /// Stream do contador de visitas
  Stream<int> watchVisitsCount(String userId) {
    if (userId.isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection('ProfileVisits')
        .where('visitedUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
          debugPrint('❌ [ProfileVisitsService] Erro no contador: $error');
          return 0;
        });
  }

  /// Busca lista de visitas (one-time fetch)
  Future<List<ProfileVisit>> fetchVisits(String userId, {int limit = 50}) async {
    if (userId.isEmpty) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('ProfileVisits')
          .where('visitedUserId', isEqualTo: userId)
          .orderBy('visitedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProfileVisit.fromDoc(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ [ProfileVisitsService] Erro ao buscar visitas: $e');
      return [];
    }
  }

  /// Busca contador de visitas (one-time fetch)
  Future<int> fetchVisitsCount(String userId) async {
    if (userId.isEmpty) {
      return 0;
    }

    try {
      final snapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('ProfileVisits')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ [ProfileVisitsService] Erro ao contar visitas: $e');
      return 0;
    }
  }

  /// Deleta uma visita específica
  Future<void> deleteVisit({
    required String userId,
    required String visitorId,
  }) async {
    try {
      final docId = '${userId}_$visitorId';
      await _firestore
          .collection('ProfileVisits')
          .doc(docId)
          .delete();
      
      debugPrint('✅ [ProfileVisitsService] Visita removida: $visitorId');
    } catch (e) {
      debugPrint('❌ [ProfileVisitsService] Erro ao remover visita: $e');
    }
  }

  /// Remove todas as visitas do usuário (limpa histórico)
  Future<void> clearAllVisits(String userId) async {
    if (userId.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('ProfileVisits')
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ [ProfileVisitsService] Todas as visitas removidas');
    } catch (e) {
      debugPrint('❌ [ProfileVisitsService] Erro ao limpar visitas: $e');
    }
  }

  /// Limpa cache local (útil após logout)
  void clearCache() {
    _lastVisitCache.clear();
    debugPrint('🗑️ [ProfileVisitsService] Cache limpo');
  }
}
