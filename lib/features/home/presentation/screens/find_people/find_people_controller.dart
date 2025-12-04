import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/features/home/presentation/services/geo_service.dart';

/// Controller para gerenciar a lista de pessoas próximas
class FindPeopleController extends ChangeNotifier {
  FindPeopleController() {
    _loadUsers();
  }

  // Estado
  bool _isLoading = true;
  String? _error;
  List<User> _users = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<User> get users => _users;
  List<String> get userIds => _users.map((u) => u.userId).toList();
  bool get isEmpty => _users.isEmpty;

  /// Carrega lista de usuários mais recentes
  Future<void> _loadUsers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('🔍 Carregando usuários da coleção Users...');

      // 1. Get current location and current user interests
      final geoService = GeoService();
      final currentLocation = await geoService.getCurrentUserLocation();
      
      List<String> myInterests = [];
      final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        final myDoc = await FirebaseFirestore.instance.collection('Users').doc(currentUserId).get();
        if (myDoc.exists) {
          myInterests = List<String>.from(myDoc.data()?['interests'] ?? []);
        }
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      debugPrint('✅ Encontrados ${querySnapshot.docs.length} usuários');

      final List<User> loadedUsers = [];
      for (var doc in querySnapshot.docs) {
        // Skip current user
        if (doc.id == currentUserId) continue;

        final data = doc.data();
        
        // Calculate distance
        if (currentLocation != null) {
           final lat = (data['latitude'] as num?)?.toDouble();
           final lng = (data['longitude'] as num?)?.toDouble();
           if (lat != null && lng != null) {
             final dist = await geoService.getDistanceToTarget(
               targetLat: lat, 
               targetLng: lng
             );
             data['distance'] = dist;
           }
        }

        // Calculate common interests
        final userInterests = List<String>.from(data['interests'] ?? []);
        final common = userInterests.toSet().intersection(myInterests.toSet()).toList();
        data['commonInterests'] = common;
        
        loadedUsers.add(User.fromDocument(data));
      }

      _users = loadedUsers;
      
      debugPrint('📋 Usuários carregados: ${_users.length}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao carregar usuários: $e');
      _error = 'Erro ao carregar pessoas próximas';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recarrega a lista
  Future<void> refresh() async {
    await _loadUsers();
  }
}

