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
      notifyListeners();

      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        _error = 'Usuário não encontrado';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = doc.data()!;
      
      // Calcular distância
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble() ?? (data['lng'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        final dist = await GeoService().getDistanceToTarget(
          targetLat: lat,
          targetLng: lng,
        );
        data['distance'] = dist;
      }

      _user = User.fromDocument({
        'userId': doc.id,
        ...data,
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados do UserCard: $e');
      _error = 'Erro ao carregar dados';
      _isLoading = false;
      notifyListeners();
    }
  }
}
