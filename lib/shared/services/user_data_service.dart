import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/core/utils/interests_helper.dart';
import 'package:partiu/shared/repositories/user_repository.dart';

/// Cache de User com TTL
class UserCache {
  final User user;
  final DateTime timestamp;

  UserCache({
    required this.user,
    required this.timestamp,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > UserDataService.userCacheTTL;
}

/// Dados de rating agregado
class RatingData {
  final double averageRating;
  final int totalReviews;

  RatingData({
    required this.averageRating,
    required this.totalReviews,
  });
}

/// Cache de ratings com TTL
class RatingCache {
  final RatingData rating;
  final DateTime timestamp;

  RatingCache({
    required this.rating,
    required this.timestamp,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > UserDataService.ratingCacheTTL;
}

/// Serviço unificado para gerenciar dados de usuários
/// 
/// Responsabilidades:
/// - ✅ Cache compartilhado de Users por userId
/// - ✅ Cache compartilhado de ratings por userId
/// - ✅ TTL configurável (Users: 5min, Ratings: 10min)
/// - ✅ Enriquecimento de dados (interesses, distância)
/// - ✅ Batch loading de ratings
/// - ✅ Evita buscar mesmo user/rating múltiplas vezes
/// 
/// Usado por:
/// - LocationQueryService (pessoas próximas)
/// - ProfileVisitsService (visitantes do perfil)
/// - Qualquer feature que precise de dados de usuários
class UserDataService {
  UserDataService._();
  
  static final UserDataService _instance = UserDataService._();
  static UserDataService get instance => _instance;

  final _firestore = FirebaseFirestore.instance;
  final _userRepository = UserRepository();
  
  // Cache de usuários por userId
  final Map<String, UserCache> _usersCache = {};
  
  // Cache de ratings por userId
  final Map<String, RatingCache> _ratingsCache = {};
  
  // TTL do cache de users (5 minutos)
  static const userCacheTTL = Duration(minutes: 5);
  
  // TTL do cache de ratings (10 minutos)
  static const ratingCacheTTL = Duration(minutes: 10);

  /// Busca um usuário por ID com cache
  /// 
  /// Se o usuário estiver em cache e não expirado, retorna do cache
  /// Caso contrário, busca do Firestore e atualiza cache
  Future<User?> getUserById(String userId) async {
    // Verificar cache
    final cached = _usersCache[userId];
    if (cached != null && !cached.isExpired) {
      debugPrint('✅ [UserDataService] User $userId do cache');
      return cached.user;
    }

    // Buscar do Firestore
    try {
      final userData = await _userRepository.getUserById(userId);
      if (userData == null) return null;

      final user = User.fromDocument(userData);
      
      // Atualizar cache
      _usersCache[userId] = UserCache(
        user: user,
        timestamp: DateTime.now(),
      );
      
      debugPrint('📥 [UserDataService] User $userId buscado e cacheado');
      return user;
    } catch (e) {
      debugPrint('❌ [UserDataService] Erro ao buscar user $userId: $e');
      return null;
    }
  }

  /// Busca múltiplos usuários em paralelo com cache
  /// 
  /// Otimiza buscando apenas os não cacheados
  Future<List<User>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    debugPrint('📥 [UserDataService] Buscando ${userIds.length} usuários...');

    // Separar usuários em cache e não cacheados
    final List<User> cachedUsers = [];
    final List<String> uncachedUserIds = [];

    for (final userId in userIds) {
      final cached = _usersCache[userId];
      if (cached != null && !cached.isExpired) {
        cachedUsers.add(cached.user);
      } else {
        uncachedUserIds.add(userId);
      }
    }

    debugPrint('✅ ${cachedUsers.length} users do cache, ${uncachedUserIds.length} para buscar');

    // Buscar não cacheados em paralelo
    if (uncachedUserIds.isNotEmpty) {
      final futures = uncachedUserIds.map((userId) async {
        final userData = await _userRepository.getUserById(userId);
        if (userData != null) {
          final user = User.fromDocument(userData);
          
          // Atualizar cache
          _usersCache[userId] = UserCache(
            user: user,
            timestamp: DateTime.now(),
          );
          
          return user;
        }
        return null;
      }).toList();

      final fetchedUsers = await Future.wait(futures);
      cachedUsers.addAll(fetchedUsers.whereType<User>());
    }

    debugPrint('✅ [UserDataService] ${cachedUsers.length} usuários retornados');
    return cachedUsers;
  }

  /// Enriquece dados de usuários com interesses em comum e distância
  /// 
  /// Modifica os objetos User in-place adicionando:
  /// - commonInterests: List<String>
  /// - distance: double?
  Future<void> enrichUsersData(
    List<User> users, {
    Map<String, dynamic>? myUserData,
  }) async {
    if (users.isEmpty) return;

    // Buscar dados do usuário atual se não fornecido
    final currentUserData = myUserData ?? await _userRepository.getCurrentUserData();
    if (currentUserData == null) {
      debugPrint('⚠️ [UserDataService] Usuário atual não encontrado');
      return;
    }

    final myInterests = List<String>.from(currentUserData['interests'] ?? []);

    // Enriquecer cada usuário
    for (var i = 0; i < users.length; i++) {
      final userData = users[i].toMap();
      
      InterestsHelper.enrichUserData(
        userData: userData,
        myInterests: myInterests,
        myUserData: currentUserData,
      );
      
      // Atualizar usuário com dados enriquecidos
      users[i] = User.fromDocument(userData);
    }

    debugPrint('✅ [UserDataService] ${users.length} usuários enriquecidos');
  }

  /// Busca rating de um usuário com cache
  Future<double?> getRatingByUserId(String userId) async {
    // Verificar cache
    final cached = _ratingsCache[userId];
    if (cached != null && !cached.isExpired) {
      debugPrint('✅ [UserDataService] Rating $userId do cache');
      return cached.rating.averageRating;
    }

    // Buscar do Firestore
    try {
      final reviewsSnapshot = await _firestore
          .collection('Reviews')
          .where('reviewee_id', isEqualTo: userId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        debugPrint('📊 [UserDataService] Nenhum review para $userId');
        return null;
      }

      final ratings = <double>[];
      for (var doc in reviewsSnapshot.docs) {
        final rating = (doc.data()['overall_rating'] as num?)?.toDouble();
        if (rating != null && rating > 0) {
          ratings.add(rating);
        }
      }

      if (ratings.isEmpty) return null;

      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      final ratingData = RatingData(
        averageRating: average,
        totalReviews: ratings.length,
      );
      
      // Atualizar cache
      _ratingsCache[userId] = RatingCache(
        rating: ratingData,
        timestamp: DateTime.now(),
      );
      
      debugPrint('📊 [UserDataService] Rating $userId: ${average.toStringAsFixed(1)} (${ratings.length} reviews)');
      return average;
    } catch (e) {
      debugPrint('❌ [UserDataService] Erro ao buscar rating de $userId: $e');
      return null;
    }
  }

  /// Busca ratings de múltiplos usuários em batch com cache
  /// 
  /// Retorna Map<userId, RatingData>
  /// Otimiza buscando apenas ratings não cacheados
  Future<Map<String, RatingData>> getRatingsByUserIds(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    debugPrint('📊 [UserDataService] Buscando ratings para ${userIds.length} usuários...');

    final Map<String, RatingData> result = {};
    final List<String> uncachedUserIds = [];

    // Separar ratings em cache e não cacheados
    for (final userId in userIds) {
      final cached = _ratingsCache[userId];
      if (cached != null && !cached.isExpired) {
        result[userId] = cached.rating;
      } else {
        uncachedUserIds.add(userId);
      }
    }

    debugPrint('✅ ${result.length} ratings do cache, ${uncachedUserIds.length} para buscar');

    // Buscar não cacheados em batch (lotes de 10)
    if (uncachedUserIds.isNotEmpty) {
      for (var i = 0; i < uncachedUserIds.length; i += 10) {
        final batch = uncachedUserIds.skip(i).take(10).toList();
        
        final reviewsSnapshot = await _firestore
            .collection('Reviews')
            .where('reviewee_id', whereIn: batch)
            .get();

        final Map<String, List<double>> ratingsByUser = {};

        for (var doc in reviewsSnapshot.docs) {
          final data = doc.data();
          final revieweeId = data['reviewee_id'] as String?;
          final rating = (data['overall_rating'] as num?)?.toDouble();

          if (revieweeId != null && rating != null && rating > 0) {
            ratingsByUser.putIfAbsent(revieweeId, () => []).add(rating);
          }
        }

        // Calcular médias e atualizar cache
        for (var entry in ratingsByUser.entries) {
          final ratings = entry.value;
          if (ratings.isNotEmpty) {
            final average = ratings.reduce((a, b) => a + b) / ratings.length;
            final ratingData = RatingData(
              averageRating: average,
              totalReviews: ratings.length,
            );
            result[entry.key] = ratingData;
            
            // Atualizar cache
            _ratingsCache[entry.key] = RatingCache(
              rating: ratingData,
              timestamp: DateTime.now(),
            );
          }
        }
      }
    }

    debugPrint('✅ [UserDataService] ${result.length} ratings retornados');
    return result;
  }

  /// Atualiza cache de um usuário específico
  void updateUserCache(String userId, User user) {
    _usersCache[userId] = UserCache(
      user: user,
      timestamp: DateTime.now(),
    );
    debugPrint('🔄 [UserDataService] Cache atualizado para $userId');
  }

  /// Invalida cache de um usuário específico
  void invalidateUserCache(String userId) {
    _usersCache.remove(userId);
    _ratingsCache.remove(userId);
    debugPrint('🗑️ [UserDataService] Cache invalidado para $userId');
  }

  /// Limpa todo o cache (útil em logout)
  void clearAllCaches() {
    _usersCache.clear();
    _ratingsCache.clear();
    debugPrint('🗑️ [UserDataService] Todo cache limpo');
  }

  /// Obtém estatísticas do cache
  Map<String, dynamic> getCacheStats() {
    final validUsers = _usersCache.values.where((c) => !c.isExpired).length;
    final validRatings = _ratingsCache.values.where((c) => !c.isExpired).length;
    
    return {
      'totalUsers': _usersCache.length,
      'validUsers': validUsers,
      'expiredUsers': _usersCache.length - validUsers,
      'totalRatings': _ratingsCache.length,
      'validRatings': validRatings,
      'expiredRatings': _ratingsCache.length - validRatings,
    };
  }
}
