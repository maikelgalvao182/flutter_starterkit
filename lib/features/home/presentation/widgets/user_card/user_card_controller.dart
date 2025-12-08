import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/core/utils/interests_helper.dart';
import 'package:partiu/shared/repositories/user_repository.dart';

/// Controller para gerenciar dados do UserCard
/// 
/// Responsabilidades:
/// - Orquestrar carregamento de dados via Repository
/// - Calcular interesses em comum e distância via Helper
/// - Gerenciar estado do widget
class UserCardController extends ChangeNotifier {
  UserCardController({
    required this.userId,
    UserRepository? repository,
  }) : _repository = repository ?? UserRepository() {
    _loadUserData();
  }

  final String userId;
  final UserRepository _repository;

  // Estado
  bool _isLoading = true;
  String? _error;
  User? _user;
  double? _overallRating;
  bool _isDisposed = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  double? get overallRating => _overallRating;

  // Getters de compatibilidade
  String? get fullName => _user?.fullName;
  String? get from => _user?.from;
  String? get photoUrl => _user?.profilePhotoUrl;
  double? get distanceKm => _user?.distance;

  /// Carrega dados do usuário com interesses em comum e distância
  /// 
  /// Arquitetura limpa:
  /// 1. Repository busca dados (queries Firestore)
  /// 2. Helper calcula interesses e distância (lógica pura)
  /// 3. Controller orquestra tudo e gerencia estado
  Future<void> _loadUserData() async {
    try {
      _isLoading = true;
      _error = null;
      if (!_isDisposed) notifyListeners();

      // 1. Buscar dados do usuário atual via Repository (com cache)
      final myUserData = await _repository.getCurrentUserData();
      
      if (_isDisposed) return;

      if (myUserData == null) {
        _error = 'Erro ao carregar usuário atual';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return;
      }

      // 2. Buscar dados do outro usuário via Repository
      final userData = await _repository.getUserById(userId);

      if (_isDisposed) return;

      if (userData == null) {
        _error = 'Usuário não encontrado';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return;
      }

      // 3. Calcular interesses em comum e distância via Helper
      final myInterests = List<String>.from(myUserData['interests'] ?? []);
      InterestsHelper.enrichUserData(
        userData: userData,
        myInterests: myInterests,
        myUserData: myUserData,
      );

      // 4. Converter para modelo User
      _user = User.fromDocument(userData);

      // 5. Buscar rating das Reviews (agregando)
      try {
        final reviewsSnapshot = await FirebaseFirestore.instance
            .collection('Reviews')
            .where('reviewee_id', isEqualTo: userId)
            .get();

        if (reviewsSnapshot.docs.isNotEmpty) {
          // Calcular média de overall_rating
          double sumRatings = 0.0;
          int count = 0;

          for (var doc in reviewsSnapshot.docs) {
            final data = doc.data();
            final rating = (data['overall_rating'] as num?)?.toDouble();
            if (rating != null && rating > 0) {
              sumRatings += rating;
              count++;
            }
          }

          if (count > 0) {
            _overallRating = sumRatings / count;
            debugPrint('📊 Rating calculado para $userId: $_overallRating de $count reviews');
          } else {
            debugPrint('⚠️ Nenhuma review com rating válido para $userId');
          }
        } else {
          debugPrint('⚠️ Nenhuma review encontrada para reviewee_id: $userId');
        }
      } catch (e) {
        debugPrint('❌ Erro ao buscar rating: $e');
        // Se falhar ao buscar rating, apenas ignora
        _overallRating = null;
      }

      debugPrint('✅ UserCard carregado: ${_user?.fullName} - ${_user?.commonInterests?.length ?? 0} interesses, ${_user?.distance?.toStringAsFixed(1) ?? '?'} km - Rating: ${_overallRating?.toStringAsFixed(1) ?? 'N/A'}');

      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados do UserCard: $e');
      
      if (_isDisposed) return;
      
      _error = 'Erro ao carregar dados';
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
