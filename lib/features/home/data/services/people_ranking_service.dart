import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/data/models/user_ranking_model.dart';

/// Serviço para gerenciar ranking de pessoas baseado em reviews
/// 
/// Responsabilidades:
/// - Buscar reviews da coleção Reviews
/// - Cruzar com dados de usuários
/// - Filtrar por cidade
/// - Retornar lista ordenada por rating
class PeopleRankingService {
  final FirebaseFirestore _firestore;

  PeopleRankingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Busca ranking de pessoas baseado em reviews
  /// 
  /// [selectedLocality] - Cidade para filtrar (opcional)
  /// [limit] - Limite de resultados (padrão: 50)
  Future<List<UserRankingModel>> getPeopleRanking({
    String? selectedLocality,
    int limit = 50,
  }) async {
    try {
      debugPrint('🔍 [PeopleRankingService] ========== INICIANDO getPeopleRanking ==========');
      debugPrint('   📍 selectedLocality: $selectedLocality');
      debugPrint('   🔢 limit: $limit');

      // PASSO 1: Buscar todas as Reviews da coleção correta
      debugPrint('\n📊 PASSO 1: Buscando Reviews...');
      
      final reviewsSnapshot = await _firestore
          .collection('Reviews')
          .orderBy('created_at', descending: true)
          .limit(500) // Busca bastante para agregar
          .get();

      debugPrint('   ✅ Reviews encontradas: ${reviewsSnapshot.docs.length}');

      if (reviewsSnapshot.docs.isEmpty) {
        debugPrint('   ⚠️ NENHUMA Review encontrada!');
        debugPrint('   💡 Verifique se a coleção Reviews existe no Firestore');
        return [];
      }

      // Log das primeiras 3 reviews
      debugPrint('   📋 Primeiras 3 Reviews:');
      for (var i = 0; i < reviewsSnapshot.docs.length && i < 3; i++) {
        final doc = reviewsSnapshot.docs[i];
        final data = doc.data();
        debugPrint('     ${i + 1}. ID: ${doc.id}');
        debugPrint('        - reviewee_id: ${data['reviewee_id']}');
        debugPrint('        - overall_rating: ${data['overall_rating']}');
        debugPrint('        - badges: ${data['badges']}');
        debugPrint('        - comment: ${data['comment']}');
      }

      // PASSO 2: Agregar reviews por reviewee_id
      debugPrint('\n👥 PASSO 2: Agregando reviews por usuário...');
      
      final Map<String, Map<String, dynamic>> aggregatedStats = {};
      
      for (var reviewDoc in reviewsSnapshot.docs) {
        final data = reviewDoc.data();
        final revieweeId = data['reviewee_id'] as String?;
        
        if (revieweeId == null || revieweeId.isEmpty) continue;
        
        if (!aggregatedStats.containsKey(revieweeId)) {
          aggregatedStats[revieweeId] = {
            'totalReviews': 0,
            'sumRatings': 0.0,
            'badges_count': <String, int>{},
            'ratings_breakdown': {
              'conversation': 0.0,
              'energy': 0.0,
              'participation': 0.0,
              'coexistence': 0.0,
            },
            'total_with_comment': 0,
          };
        }
        
        final stats = aggregatedStats[revieweeId]!;
        
        // Contar review
        stats['totalReviews'] = (stats['totalReviews'] as int) + 1;
        
        // Somar rating
        final rating = (data['overall_rating'] as num?)?.toDouble() ?? 0.0;
        stats['sumRatings'] = (stats['sumRatings'] as double) + rating;
        
        // Contar badges
        final badges = data['badges'] as List?;
        if (badges != null) {
          final badgesCounts = stats['badges_count'] as Map<String, int>;
          for (var badge in badges) {
            final badgeName = badge.toString();
            badgesCounts[badgeName] = (badgesCounts[badgeName] ?? 0) + 1;
          }
        }
        
        // Somar criteria ratings
        final criteriaRatings = data['criteria_ratings'] as Map?;
        if (criteriaRatings != null) {
          final breakdown = stats['ratings_breakdown'] as Map;
          breakdown['conversation'] = (breakdown['conversation'] as double) + 
              ((criteriaRatings['conversation'] as num?)?.toDouble() ?? 0.0);
          breakdown['energy'] = (breakdown['energy'] as double) + 
              ((criteriaRatings['energy'] as num?)?.toDouble() ?? 0.0);
          breakdown['participation'] = (breakdown['participation'] as double) + 
              ((criteriaRatings['participation'] as num?)?.toDouble() ?? 0.0);
          breakdown['coexistence'] = (breakdown['coexistence'] as double) + 
              ((criteriaRatings['coexistence'] as num?)?.toDouble() ?? 0.0);
        }
        
        // Contar comentários
        final comment = data['comment'] as String?;
        if (comment != null && comment.isNotEmpty) {
          stats['total_with_comment'] = (stats['total_with_comment'] as int) + 1;
        }
      }

      // Calcular médias
      for (var entry in aggregatedStats.entries) {
        final stats = entry.value;
        final totalReviews = stats['totalReviews'] as int;
        
        // Média geral
        stats['overallRating'] = (stats['sumRatings'] as double) / totalReviews;
        
        // Médias dos critérios
        final breakdown = stats['ratings_breakdown'] as Map;
        breakdown['conversation'] = (breakdown['conversation'] as double) / totalReviews;
        breakdown['energy'] = (breakdown['energy'] as double) / totalReviews;
        breakdown['participation'] = (breakdown['participation'] as double) / totalReviews;
        breakdown['coexistence'] = (breakdown['coexistence'] as double) / totalReviews;
      }

      debugPrint('   ✅ Usuários com reviews: ${aggregatedStats.length}');
      debugPrint('   📋 Primeiros 3 agregados:');
      int logCount = 0;
      for (var entry in aggregatedStats.entries) {
        if (logCount >= 3) break;
        debugPrint('     ${logCount + 1}. UserId: ${entry.key}');
        debugPrint('        - totalReviews: ${entry.value['totalReviews']}');
        debugPrint('        - overallRating: ${entry.value['overallRating']}');
        debugPrint('        - badges_count: ${entry.value['badges_count']}');
        logCount++;
      }

      // PASSO 3: Buscar dados dos usuários em lotes
      debugPrint('\n👤 PASSO 3: Buscando dados dos usuários...');
      
      final userIds = aggregatedStats.keys.toList();
      final Map<String, Map<String, dynamic>> usersData = {};
      
      // Dividir em chunks de 10
      int chunkIndex = 0;
      for (var i = 0; i < userIds.length; i += 10) {
        final chunk = userIds.skip(i).take(10).toList();
        chunkIndex++;
        
        debugPrint('   🔄 Chunk $chunkIndex: Buscando ${chunk.length} usuários...');
        
        final usersSnapshot = await _firestore
            .collection('Users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        debugPrint('      ✅ Encontrados: ${usersSnapshot.docs.length} documentos');

        for (var doc in usersSnapshot.docs) {
          if (doc.exists && doc.data().isNotEmpty) {
            usersData[doc.id] = doc.data();
          }
        }
      }

      debugPrint('   ✅ Usuários carregados: ${usersData.length}/${userIds.length}');

      // PASSO 4: Montar ranking cruzando Stats + Users
      debugPrint('\n🏆 PASSO 4: Montando ranking...');
      
      final List<UserRankingModel> rankings = [];
      int skippedNoUser = 0;
      int skippedByCity = 0;

      for (var entry in aggregatedStats.entries) {
        final userId = entry.key;
        final statsData = entry.value;
        final userData = usersData[userId];

        // Pular se não temos dados do usuário
        if (userData == null) {
          skippedNoUser++;
          continue;
        }

        final userLocality = userData['locality'] as String? ?? '';
        
        // Filtrar por cidade se especificado
        if (selectedLocality != null && 
            selectedLocality.isNotEmpty && 
            userLocality != selectedLocality) {
          skippedByCity++;
          continue;
        }

        // Criar modelo de ranking
        final ranking = UserRankingModel.fromData(
          userId: userId,
          userData: userData,
          statsData: statsData,
        );

        rankings.add(ranking);
        
        // Log dos primeiros 3
        if (rankings.length <= 3) {
          debugPrint('   ✅ #${rankings.length}: ${ranking.fullName}');
          debugPrint('      - Rating: ${ranking.overallRating}⭐');
          debugPrint('      - Reviews: ${ranking.totalReviews}');
          debugPrint('      - Locality: ${ranking.locality}');
          debugPrint('      - Badges: ${ranking.badgesCount.length}');
        }
      }

      debugPrint('\n📊 RESUMO:');
      debugPrint('   ✅ Rankings montados: ${rankings.length}');
      debugPrint('   ⚠️ Usuários sem dados: $skippedNoUser');
      debugPrint('   🔍 Filtrados por cidade: $skippedByCity');

      // PASSO 5: Ordenar por rating (melhor primeiro)
      debugPrint('\n🔄 PASSO 5: Ordenando por rating...');
      
      rankings.sort((a, b) {
        // Primeiro por rating
        final ratingComparison = b.overallRating.compareTo(a.overallRating);
        if (ratingComparison != 0) return ratingComparison;
        
        // Desempate por total de reviews
        return b.totalReviews.compareTo(a.totalReviews);
      });

      // Limitar ao número solicitado
      final result = rankings.take(limit).toList();
      
      debugPrint('\n🏆 RANKING FINAL (Top ${result.length}):');
      for (var i = 0; i < result.length && i < 5; i++) {
        final r = result[i];
        debugPrint('   ${i + 1}º: ${r.fullName} - ${r.overallRating}⭐ (${r.totalReviews} reviews) - ${r.locality}');
      }
      
      debugPrint('========== FIM getPeopleRanking ==========\n');

      return result;
    } catch (error, stackTrace) {
      debugPrint('❌ ERRO CRÍTICO em getPeopleRanking:');
      debugPrint('   Error: $error');
      debugPrint('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Busca lista de cidades disponíveis (com reviews)
  /// 
  /// Retorna lista ordenada de cidades onde existem usuários avaliados
  Future<List<String>> getAvailableCities() async {
    try {
      debugPrint('🌆 [PeopleRankingService] ========== INICIANDO getAvailableCities ==========');

      // Buscar reviews para extrair reviewee_ids
      debugPrint('   📊 Buscando Reviews...');
      
      final reviewsSnapshot = await _firestore
          .collection('Reviews')
          .limit(500) // Limite razoável
          .get();

      debugPrint('   ✅ Reviews encontradas: ${reviewsSnapshot.docs.length}');

      if (reviewsSnapshot.docs.isEmpty) {
        debugPrint('   ⚠️ Nenhuma Review encontrada');
        return [];
      }

      // Extrair IDs únicos dos reviewees
      final userIds = reviewsSnapshot.docs
          .map((doc) => doc.data()['reviewee_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .toList();

      debugPrint('   👥 Total de userIds com reviews: ${userIds.length}');

      // Buscar dados dos usuários em lotes
      final Set<String> cities = {};
      
      int chunkIndex = 0;
      for (var i = 0; i < userIds.length; i += 10) {
        final chunk = userIds.skip(i).take(10).toList();
        chunkIndex++;
        
        debugPrint('   🔄 Chunk $chunkIndex: Buscando ${chunk.length} usuários...');
        
        final usersSnapshot = await _firestore
            .collection('Users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in usersSnapshot.docs) {
          final locality = doc.data()['locality'] as String?;
          if (locality != null && locality.isNotEmpty) {
            cities.add(locality);
          }
        }
        
        debugPrint('      ✅ Cidades únicas até agora: ${cities.length}');
      }

      // Converter para lista ordenada
      final result = cities.toList()..sort();
      
      debugPrint('\n🌆 RESULTADO:');
      debugPrint('   ✅ Cidades encontradas: ${result.length}');
      if (result.isNotEmpty) {
        debugPrint('   📋 Primeiras 10: ${result.take(10).join(", ")}');
      }
      debugPrint('========== FIM getAvailableCities ==========\n');

      return result;
    } catch (error, stackTrace) {
      debugPrint('❌ ERRO em getAvailableCities:');
      debugPrint('   Error: $error');
      debugPrint('   StackTrace: $stackTrace');
      return [];
    }
  }
}
