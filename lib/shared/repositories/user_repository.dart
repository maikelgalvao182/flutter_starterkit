import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:partiu/shared/models/user_model.dart';

/// Repository centralizado para queries da coleção Users
/// 
/// Evita duplicação de código ao reutilizar queries comuns
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Cache do usuário atual para evitar queries repetidas na mesma sessão
  static Map<String, dynamic>? _currentUserCache;
  static String? _cachedUserId;

  /// Limpa o cache do usuário atual (usar no logout)
  static void clearCache() {
    _currentUserCache = null;
    _cachedUserId = null;
  }

  /// Referência à coleção Users
  CollectionReference get _usersCollection => _firestore.collection('Users');

  /// Busca um usuário por ID
  /// 
  /// Retorna null se não encontrado
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      
      if (!doc.exists) {
        debugPrint('⚠️ Usuário não encontrado: $userId');
        return null;
      }

      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    } catch (e) {
      debugPrint('❌ Erro ao buscar usuário $userId: $e');
      return null;
    }
  }

  /// Busca múltiplos usuários por IDs (batch otimizado)
  /// 
  /// Retorna Map<userId, userData> para acesso rápido
  /// Firestore whereIn aceita até 10 IDs por query
  Future<Map<String, Map<String, dynamic>>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    try {
      final results = <String, Map<String, dynamic>>{};
      
      // Dividir em chunks de 10 (limite do whereIn)
      for (var i = 0; i < userIds.length; i += 10) {
        final chunk = userIds.skip(i).take(10).toList();
        
        final snapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          results[doc.id] = {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }
      }

      return results;
    } catch (e) {
      debugPrint('❌ Erro ao buscar usuários por IDs: $e');
      return {};
    }
  }

  /// Busca dados básicos de um usuário (photoUrl + fullName)
  /// 
  /// Usado para exibir avatar + nome em listas
  Future<Map<String, dynamic>?> getUserBasicInfo(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return {
        'userId': userId,
        'photoUrl': data['photoUrl'] as String?,
        'fullName': data['fullName'] as String?,
      };
    } catch (e) {
      debugPrint('❌ Erro ao buscar info básica do usuário $userId: $e');
      return null;
    }
  }

  /// Busca dados básicos de múltiplos usuários (batch)
  /// 
  /// Retorna List para manter ordem original dos IDs
  Future<List<Map<String, dynamic>>> getUsersBasicInfo(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final usersMap = await getUsersByIds(userIds);
      
      // Retornar na ordem original dos IDs, filtrar nulls
      return userIds
          .map((userId) {
            final userData = usersMap[userId];
            if (userData == null) return null;
            
            return {
              'userId': userId,
              'photoUrl': userData['photoUrl'] as String?,
              'fullName': userData['fullName'] as String?,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar info básica de usuários: $e');
      return [];
    }
  }

  /// Stream de dados do usuário (para listeners em tempo real)
  Stream<Map<String, dynamic>?> watchUser(String userId) {
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        });
  }

  /// Atualiza dados de um usuário
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(userId).update(data);
      debugPrint('✅ Usuário atualizado: $userId');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar usuário $userId: $e');
      rethrow;
    }
  }

  /// Cria um novo usuário
  Future<void> createUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(userId).set(data);
      debugPrint('✅ Usuário criado: $userId');
    } catch (e) {
      debugPrint('❌ Erro ao criar usuário $userId: $e');
      rethrow;
    }
  }

  /// Verifica se usuário existe
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Erro ao verificar existência do usuário $userId: $e');
      return false;
    }
  }

  /// Busca o usuário mais recente cadastrado
  Future<UserModel?> getMostRecentUser() async {
    try {
      final snap = await _usersCollection
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      return UserModel.fromFirestore(snap.docs.first);
    } catch (e) {
      debugPrint('❌ Erro ao buscar usuário mais recente: $e');
      return null;
    }
  }

  /// Busca dados completos do usuário atual autenticado (com cache)
  /// 
  /// Usa cache estático para evitar múltiplas queries ao mesmo usuário
  /// na mesma sessão. Útil para cálculos de distância e interesses.
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return null;

    // Retorna do cache se disponível e válido
    if (_currentUserCache != null && _cachedUserId == currentUserId) {
      return _currentUserCache;
    }

    try {
      final doc = await _usersCollection.doc(currentUserId).get();
      
      if (!doc.exists) {
        debugPrint('⚠️ Usuário atual não encontrado: $currentUserId');
        return null;
      }

      _currentUserCache = {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
      _cachedUserId = currentUserId;

      debugPrint('✅ Cache do usuário atual atualizado: $currentUserId');
      return _currentUserCache;
    } catch (e) {
      debugPrint('❌ Erro ao buscar dados do usuário atual: $e');
      return null;
    }
  }
}
