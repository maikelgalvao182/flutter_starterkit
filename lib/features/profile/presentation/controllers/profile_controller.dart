import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/core/models/review_model.dart';
import 'package:partiu/core/models/review_stats_model.dart';
import 'package:partiu/shared/stores/user_store.dart';

/// Controller MVVM para tela de perfil
/// 
/// Responsabilidades:
/// - Carrega dados do usuário do Firestore
/// - Gerencia estado de loading/error
/// - Integra com UserStore para dados reativos
/// - Carrega reviews e estatísticas
class ProfileController {
  ProfileController({required this.userId, User? initialUser}) {
    if (initialUser != null) {
      profile.value = initialUser;
    }
  }

  final String userId;

  // State
  final ValueNotifier<User?> profile = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<Review>> reviews = ValueNotifier([]);
  final ValueNotifier<ReviewStats?> reviewStats = ValueNotifier(null);

  StreamSubscription<DocumentSnapshot>? _profileSubscription;
  StreamSubscription<QuerySnapshot>? _reviewsSubscription;

  final _firestore = FirebaseFirestore.instance;

  /// Avatar URL reativo (via UserStore)
  ValueNotifier<String> get avatarUrl {
    final notifier = ValueNotifier<String>('');
    
    // Obtém URL diretamente do UserStore
    final url = UserStore.instance.getAvatarUrl(userId);
    if (url != null && url.isNotEmpty) {
      notifier.value = url;
    }
    
    return notifier;
  }

  /// Carrega dados do perfil
  Future<void> load(String targetUserId) async {
    isLoading.value = true;
    error.value = null;

    try {
      // Inicia listener do perfil
      _profileSubscription = _firestore
          .collection('Users')
          .doc(targetUserId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists && snapshot.data() != null) {
                profile.value = User.fromDocument(snapshot.data()!);
                error.value = null;
              } else {
                error.value = 'Usuário não encontrado';
              }
              isLoading.value = false;
            },
            onError: (e) {
              error.value = 'Erro ao carregar perfil: $e';
              isLoading.value = false;
            },
          );

      // Carrega reviews
      await _loadReviews(targetUserId);
    } catch (e) {
      error.value = 'Erro ao carregar perfil: $e';
      isLoading.value = false;
    }
  }

  /// Carrega reviews do usuário
  Future<void> _loadReviews(String targetUserId) async {
    try {
      _reviewsSubscription = _firestore
          .collection('Reviews')
          .where('revieweeId', isEqualTo: targetUserId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        final loadedReviews = snapshot.docs
            .map((doc) => Review.fromFirestore(doc.data(), doc.id))
            .toList();

        reviews.value = loadedReviews;

        // Calcula estatísticas
        if (loadedReviews.isNotEmpty) {
          final reviewData = snapshot.docs.map((doc) => doc.data()).toList();
          reviewStats.value = ReviewStats.fromReviews(reviewData);
        } else {
          reviewStats.value = const ReviewStats(
            totalReviews: 0,
            overallRating: 0.0,
          );
        }
      });
    } catch (e) {
      debugPrint('Erro ao carregar reviews: $e');
    }
  }

  /// Refresh manual
  Future<void> refresh(String targetUserId) async {
    await load(targetUserId);
  }

  /// Registra visita ao perfil
  Future<void> registerVisit(String currentUserId) async {
    if (currentUserId.isEmpty || currentUserId == userId) {
      return; // Não registra visita no próprio perfil
    }

    try {
      await _firestore.collection('Visits').add({
        'visitorId': currentUserId,
        'visitedUserId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'profile',
      });
    } catch (e) {
      debugPrint('Erro ao registrar visita: $e');
    }
  }

  /// Verifica se é o próprio perfil
  bool isMyProfile(String currentUserId) {
    return userId == currentUserId;
  }

  /// Libera recursos
  void release() {
    _profileSubscription?.cancel();
    _reviewsSubscription?.cancel();
    profile.dispose();
    isLoading.dispose();
    error.dispose();
    reviews.dispose();
    reviewStats.dispose();
  }
}
