import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

/// Helper para calcular interesses em comum entre usuários
class InterestsHelper {
  /// Carrega os interesses do usuário atual autenticado
  static Future<List<String>> loadCurrentUserInterests() async {
    final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return [];

    try {
      final myDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .get();

      if (myDoc.exists) {
        return List<String>.from(myDoc.data()?['interests'] ?? []);
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar interesses do usuário atual: $e');
    }

    return [];
  }

  /// Calcula interesses em comum entre duas listas de interesses
  static List<String> calculateCommonInterests(
    List<String> userInterests,
    List<String> myInterests,
  ) {
    return userInterests.toSet().intersection(myInterests.toSet()).toList();
  }

  /// Carrega usuário do Firestore e adiciona interesses em comum
  /// 
  /// Retorna um Map com os dados do usuário incluindo:
  /// - userId
  /// - commonInterests
  /// - todos os campos do documento original
  static Future<Map<String, dynamic>?> loadUserWithCommonInterests(
    String userId,
    List<String> myInterests,
  ) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return null;

      final data = Map<String, dynamic>.from(userDoc.data()!);
      data['userId'] = userId;

      // Calcular interesses em comum
      final userInterests = List<String>.from(data['interests'] ?? []);
      final common = calculateCommonInterests(userInterests, myInterests);
      data['commonInterests'] = common;

      debugPrint('✅ User $userId: ${common.length} interesses em comum');

      return data;
    } catch (e) {
      debugPrint('❌ Erro ao carregar user $userId: $e');
      return null;
    }
  }
}
