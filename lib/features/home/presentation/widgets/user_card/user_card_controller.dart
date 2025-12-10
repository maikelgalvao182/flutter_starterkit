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
  String? get photoUrl => _user?.photoUrl;
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

      debugPrint('✅ UserCard carregado: ${_user?.fullName} - ${_user?.commonInterests?.length ?? 0} interesses, ${_user?.distance?.toStringAsFixed(1) ?? '?'} km - Rating: ${_user?.overallRating?.toStringAsFixed(1) ?? 'N/A'}');

      // 5. Rating vem diretamente do documento Users (sincronizado via Cloud Function)
      _overallRating = _user?.overallRating;

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
