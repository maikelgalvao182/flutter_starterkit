import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/features/home/presentation/services/geo_service.dart';

/// Controller para gerenciar dados do UserCard
class UserCardController extends ChangeNotifier {
  UserCardController({required this.userId}) {
    _loadUserData();
  }

  final String userId;

  // Estado
  bool _isLoading = true;
  String? _error;
  User? _user;
  bool _isDisposed = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;

  // Getters de compatibilidade (opcional, se ainda usados em outros lugares)
  String? get fullName => _user?.fullName;
  String? get from => _user?.from;
  String? get photoUrl => _user?.profilePhotoUrl;
  double? get distanceKm => _user?.distance;

  /// Carrega dados do usuário do Firestore
  Future<void> _loadUserData() async {
    try {
      _isLoading = true;
      _error = null;
      if (!_isDisposed) notifyListeners();

      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (_isDisposed) return;

      if (!doc.exists) {
        _error = 'Usuário não encontrado';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return;
      }

      final data = doc.data()!;
      
      // Calcular distância
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        final dist = await GeoService().getDistanceToTarget(
          targetLat: lat,
          targetLng: lng,
        );
        
        if (_isDisposed) return;
        
        data['distance'] = dist;
      }

      if (_isDisposed) return;

      _user = User.fromDocument({
        'userId': doc.id,
        ...data,
      });

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
