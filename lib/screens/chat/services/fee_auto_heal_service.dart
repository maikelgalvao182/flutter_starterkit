import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço responsável pela lógica de auto-heal de fee_lock
/// Move operações pesadas para background, evitando bloqueios na UI
class FeeAutoHealService {
  factory FeeAutoHealService() => _instance;
  FeeAutoHealService._internal();
  static final FeeAutoHealService _instance = FeeAutoHealService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache para evitar processamento duplicado
  final Set<String> _processedConversations = {};
  
  // Timer para debounce de operações
  Timer? _debounceTimer;

  /// Processa auto-heal de fee_lock de forma assíncrona
  /// Não bloqueia a UI principal
  Future<void> processAutoHeal({
    required String conversationId,
    required String currentUserId,
    required String otherUserId,
    required Map<String, dynamic> conversationData,
  }) async {
    // Cancelar operação anterior se existir (debounce)
    _debounceTimer?.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performAutoHeal(
        conversationId: conversationId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        conversationData: conversationData,
      );
    });
  }

  /// Executa a lógica de auto-heal de forma assíncrona
  Future<void> _performAutoHeal({
    required String conversationId,
    required String currentUserId,
    required String otherUserId,
    required Map<String, dynamic> conversationData,
  }) async {
    try {
      // Verificar se já foi processado para evitar duplicação
      final cacheKey = '${currentUserId}_$otherUserId';
      if (_processedConversations.contains(cacheKey)) {
        return;
      }

      final hasRelated = conversationData['related_application_id'] != null;
      final hasFee = conversationData['fee_lock'] == true || 
                     conversationData['payment_status'] == 'paid';

      if (!hasRelated || hasFee) {
        return; // Não precisa de auto-heal
      }
      
      // Marcar como processado
      _processedConversations.add(cacheKey);

      final parts = (conversationData['related_application_id'] as String).split('::');
      if (parts.length != 3) {
        return;
      }

      final announcementId = parts[0];
      final categoryId = parts[1];

      // Recuperar wedding announcement (operação async)
      final feeUSD = await _calculateFee(announcementId, categoryId);
      
      // Aplicar fee_lock em ambas as conversações
      await _applyFeeLock(currentUserId, otherUserId, feeUSD);
      
      
    } catch (e) {
      // Remover do cache em caso de erro para permitir retry
      final cacheKey = '${currentUserId}_$otherUserId';
      _processedConversations.remove(cacheKey);
    }
  }

  /// Calcula o fee baseado no wedding announcement
  Future<int> _calculateFee(String announcementId, String categoryId) async {
    try {
      // TODO: Implement fee calculation logic when fee_calculation model is available
      // For now, return a default fee based on simple logic
      final announcement = await _firestore
          .collection('WeddingAnnouncements')
          .doc(announcementId)
          .get();
      
      if (!announcement.exists) return 10;
      
      final data = announcement.data();
      final budgetRange = data?['budgetRange'] as String?;
      
      // Simple fee calculation based on budget range
      if (budgetRange == null) return 10;
      if (budgetRange.contains('Under')) return 3;
      if (budgetRange.contains('1') && budgetRange.contains('3')) return 5;
      if (budgetRange.contains('3') && budgetRange.contains('5')) return 10;
      if (budgetRange.contains('5') && budgetRange.contains('10')) return 15;
      if (budgetRange.contains('Over')) return 20;
      
      return 10; // Fallback fee
    } catch (e) {
      return 10; // Fallback fee
    }
  }

  /// Aplica fee_lock em ambas as conversações
  Future<void> _applyFeeLock(String currentUserId, String otherUserId, int feeUSD) async {
    final now = FieldValue.serverTimestamp();
    
    final lockData = {
      'fee_lock': true,
      'payment_status': 'pending',
      'required_fee_usd': feeUSD,
      'payment_cta_inserted': true,
      'timestamp': now,
    };

    // Aplicar em paralelo para otimizar performance
    await Future.wait([
      _firestore
          .collection('Connections')
          .doc(currentUserId)
          .collection('Conversations')
          .doc(otherUserId)
          .set(lockData, SetOptions(merge: true)),
      _firestore
          .collection('Connections')
          .doc(otherUserId)
          .collection('Conversations')
          .doc(currentUserId)
          .set(lockData, SetOptions(merge: true)),
    ]);
  }

  /// Limpar cache de conversações processadas
  void clearCache() {
    _processedConversations.clear();
  }

  /// Cancelar operações pendentes
  void dispose() {
    _debounceTimer?.cancel();
    clearCache();
  }

  /// Get estatísticas do serviço
  Map<String, dynamic> getStats() {
    return {
      'processed_conversations': _processedConversations.length,
      'has_pending_timer': _debounceTimer?.isActive ?? false,
    };
  }
}
