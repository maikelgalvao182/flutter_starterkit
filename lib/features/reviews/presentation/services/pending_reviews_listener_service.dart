import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/features/reviews/presentation/services/pending_reviews_checker_service.dart';

/// Serviço de listener em tempo real para PendingReviews
/// 
/// Monitora a coleção PendingReviews no Firestore e dispara automaticamente
/// o ReviewDialog quando um novo registro é criado.
/// 
/// Similar aos listeners de notificações e mensagens, este serviço roda em background
/// e detecta mudanças em tempo real via Firestore snapshots.
class PendingReviewsListenerService {
  static PendingReviewsListenerService? _instance;
  
  static PendingReviewsListenerService get instance {
    _instance ??= PendingReviewsListenerService._();
    return _instance!;
  }

  PendingReviewsListenerService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  BuildContext? _context;
  bool _isListening = false;
  
  // Track last known pending review IDs to detect NEW reviews
  final Set<String> _knownPendingReviewIds = {};

  /// Inicializa o listener de pending reviews
  /// 
  /// [context]: BuildContext necessário para mostrar dialogs
  void startListening(BuildContext context) {
    if (_isListening) {
      AppLogger.info('[PendingReviewsListener] Já está ouvindo mudanças');
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      AppLogger.info('[PendingReviewsListener] UserId vazio, não pode iniciar listener');
      return;
    }

    _context = context;
    _isListening = true;

    AppLogger.info('[PendingReviewsListener] 🎯 Iniciando listener para userId: $userId');

    // Listener em tempo real para PendingReviews onde reviewer_id == userId
    _subscription = _firestore
        .collection('PendingReviews')
        .where('reviewer_id', isEqualTo: userId)
        .where('dismissed', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            AppLogger.info('[PendingReviewsListener] 📸 Snapshot recebido! Documentos: ${snapshot.docs.length}');
            if (snapshot.docs.isNotEmpty) {
              for (final doc in snapshot.docs) {
                final data = doc.data();
                AppLogger.info('[PendingReviewsListener] 📄 Doc ${doc.id}:');
                AppLogger.info('   - reviewer_id: ${data['reviewer_id']}');
                AppLogger.info('   - dismissed: ${data['dismissed']}');
                AppLogger.info('   - created_at: ${data['created_at']}');
                AppLogger.info('   - event_id: ${data['event_id']}');
              }
            }
            _handleSnapshot(snapshot);
          },
          onError: (error) {
            AppLogger.error('[PendingReviewsListener] ❌ Erro no stream', error: error);
          },
        );
    
    AppLogger.info('[PendingReviewsListener] ✅ Listener configurado e aguardando snapshots...');
  }

  /// Para o listener
  void stopListening() {
    if (!_isListening) return;

    AppLogger.info('[PendingReviewsListener] Parando listener');
    _subscription?.cancel();
    _subscription = null;
    _context = null;
    _isListening = false;
    _knownPendingReviewIds.clear();
  }

  /// Processa mudanças no snapshot
  void _handleSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    AppLogger.info('[PendingReviewsListener] 📸 Snapshot recebido! Documentos: ${snapshot.docs.length}');
    
    if (_context == null || !_context!.mounted) {
      AppLogger.info('[PendingReviewsListener] ⚠️ Context não disponível, ignorando snapshot');
      return;
    }

    // First snapshot: populate known IDs AND trigger dialogs for existing reviews
    if (_knownPendingReviewIds.isEmpty && snapshot.docs.isNotEmpty) {
      for (final doc in snapshot.docs) {
        _knownPendingReviewIds.add(doc.id);
      }
      AppLogger.info('[PendingReviewsListener] 🔔 Inicialização: ${_knownPendingReviewIds.length} reviews existentes detectados!');
      
      // Aguardar um frame para garantir que o contexto está pronto
      Future.delayed(const Duration(milliseconds: 500), () {
        _showReviewDialogsForExistingReviews();
      });
      return;
    }
    
    // Se não há documentos e é o primeiro snapshot
    if (_knownPendingReviewIds.isEmpty && snapshot.docs.isEmpty) {
      AppLogger.info('[PendingReviewsListener] ✅ Nenhum pending review encontrado (lista vazia)');
      return;
    }

    // Detect NEW pending reviews (not in known set)
    final newReviewIds = <String>[];
    
    for (final doc in snapshot.docs) {
      if (!_knownPendingReviewIds.contains(doc.id)) {
        newReviewIds.add(doc.id);
        _knownPendingReviewIds.add(doc.id);
      }
    }

    // Detect REMOVED pending reviews (dismissed or deleted)
    final currentIds = snapshot.docs.map((doc) => doc.id).toSet();
    _knownPendingReviewIds.removeWhere((id) => !currentIds.contains(id));

    if (newReviewIds.isEmpty) {
      return;
    }

    AppLogger.info('[PendingReviewsListener] 🔔 ${newReviewIds.length} novos pending reviews detectados!');

    // Trigger review prompt service to show dialogs for new reviews
    _showReviewDialogsForNewReviews();
  }

  /// Mostra dialogs de review para pending reviews existentes (primeira carga)
  Future<void> _showReviewDialogsForExistingReviews() async {
    if (_context == null || !_context!.mounted) {
      return;
    }

    try {
      await PendingReviewsCheckerService().checkAndShowPendingReviews(
        _context!,
        forceRefresh: true,
      );
    } catch (e) {
      AppLogger.error('[PendingReviewsListener] Erro ao mostrar dialogs', error: e);
    }
  }

  /// Mostra dialogs de review para novos pending reviews
  Future<void> _showReviewDialogsForNewReviews() async {
    if (_context == null || !_context!.mounted) {
      return;
    }

    try {
      await PendingReviewsCheckerService().checkAndShowPendingReviews(
        _context!,
        forceRefresh: true,
      );
    } catch (e) {
      AppLogger.error('[PendingReviewsListener] Erro ao mostrar dialogs', error: e);
    }
  }

  /// Reset do estado (útil para logout)
  void reset() {
    stopListening();
    _knownPendingReviewIds.clear();
  }

  /// Limpa um pending review específico do cache local
  void clearPendingReview(String pendingReviewId) {
    _knownPendingReviewIds.remove(pendingReviewId);
    AppLogger.info('[PendingReviewsListener] 🗑️ Pending review removido do cache: $pendingReviewId');
  }

  /// Retorna o número de pending reviews conhecidos
  int get pendingReviewsCount => _knownPendingReviewIds.length;
}
