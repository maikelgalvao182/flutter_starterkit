import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/core/utils/interests_helper.dart';
import 'package:partiu/services/location/location_query_service.dart';
import 'package:partiu/services/location/distance_isolate.dart';
import 'package:partiu/shared/repositories/user_repository.dart';
import 'package:partiu/shared/services/user_data_service.dart';

/// Controller para gerenciar a lista de pessoas próximas
/// 
/// Usa LocationQueryService para buscar usuários dentro do raio configurado
/// com filtros sociais (gênero, idade, verificado, interesses)
/// 
/// ✅ Usa ValueNotifiers para rebuild granular (evita rebuilds desnecessários)
class FindPeopleController {
  FindPeopleController() {
    _initializeStream();
  }

  // Serviço de localização
  final LocationQueryService _locationService = LocationQueryService();
  final UserDataService _userDataService = UserDataService.instance;
  
  // Subscription do stream
  StreamSubscription<List<UserWithDistance>>? _usersSubscription;
  
  // Flag para evitar conversão simultânea
  bool _isConverting = false;

  // Estado usando ValueNotifiers para rebuild granular
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<User>> users = ValueNotifier([]);

  // Getters
  List<String> get userIds => users.value.map((u) => u.userId).toList();
  bool get isEmpty => users.value.isEmpty && !isLoading.value;

  /// Inicializa stream de usuários próximos
  void _initializeStream() {
    debugPrint('🔍 FindPeopleController: Inicializando stream de usuários');
    
    // Escutar stream de atualizações automáticas
    _usersSubscription = _locationService.usersStream.listen(
      _onUsersChanged,
      onError: _onUsersError,
    );
    
    // Carregar usuários inicialmente (após setup do stream)
    _loadInitialUsers();
  }

  /// Carrega usuários inicialmente
  Future<void> _loadInitialUsers() async {
    try {
      isLoading.value = true;
      error.value = null;

      debugPrint('🔍 FindPeopleController: Carregando usuários próximos...');
      
      final usersWithDistance = await _locationService.getUsersWithinRadiusOnce();
      
      await _convertToUsers(usersWithDistance);
      
      isLoading.value = false;
    } catch (e) {
      debugPrint('❌ FindPeopleController: Erro ao carregar usuários: $e');
      error.value = 'Erro ao carregar pessoas próximas';
      isLoading.value = false;
    }
  }

  /// Callback quando usuários mudam no stream
  void _onUsersChanged(List<UserWithDistance> usersWithDistance) async {
    if (_isConverting) {
      debugPrint('⚠️ FindPeopleController: Conversão já em andamento, ignorando stream update');
      return;
    }
    
    debugPrint('🔄 FindPeopleController: Stream recebeu ${usersWithDistance.length} usuários');
    
    await _convertToUsers(usersWithDistance);
    
    isLoading.value = false;
    error.value = null;
  }

  /// Callback quando ocorre erro no stream
  void _onUsersError(Object err) {
    debugPrint('❌ FindPeopleController: Erro no stream: $err');
    
    error.value = 'Erro ao carregar pessoas próximas';
    isLoading.value = false;
  }

  /// Converte UserWithDistance para User
  Future<void> _convertToUsers(List<UserWithDistance> usersWithDistance) async {
    if (_isConverting) {
      debugPrint('⚠️ FindPeopleController: _convertToUsers já está executando');
      return;
    }
    
    _isConverting = true;
    
    try {
      final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      
      // Carregar interesses do usuário atual via Repository
      final repository = UserRepository();
      final myUserData = await repository.getCurrentUserData();
      final myInterests = myUserData != null 
          ? List<String>.from(myUserData['interests'] ?? [])
          : <String>[];

      final List<User> loadedUsers = [];
      
      // Extrair userIds para buscar ratings
      final userIds = usersWithDistance.map((u) => u.userId).toList();
      
      // Buscar ratings em batch usando UserDataService
      final ratingsMap = await _userDataService.getRatingsByUserIds(userIds);
      
      for (final userWithDist in usersWithDistance) {
        final data = Map<String, dynamic>.from(userWithDist.userData);
        
        // Adicionar campos computados
        data['userId'] = userWithDist.userId;
        data['distance'] = userWithDist.distanceKm;
        
        // Calcular interesses em comum usando Helper
        final userInterests = List<String>.from(data['interests'] ?? []);
        final common = InterestsHelper.calculateCommonInterests(userInterests, myInterests);
        data['commonInterests'] = common;
        
        // Adicionar rating do cache
        final rating = ratingsMap[userWithDist.userId];
        if (rating != null) {
          data['overallRating'] = rating.averageRating;
          data['totalReviews'] = rating.totalReviews;
        }
        
        loadedUsers.add(User.fromDocument(data));
      }
      
      // Ordenar por distância (mais próximos primeiro)
      loadedUsers.sort((a, b) {
        final distA = a.distance ?? double.infinity;
        final distB = b.distance ?? double.infinity;
        return distA.compareTo(distB);
      });

      users.value = loadedUsers;
    } finally {
      _isConverting = false;
    }
  }

  /// Recarrega a lista forçando invalidação do cache
  Future<void> refresh() async {
    debugPrint('🔄 FindPeopleController: Refresh solicitado');
    _locationService.forceReload();
  }

  void dispose() {
    _usersSubscription?.cancel();
    isLoading.dispose();
    error.dispose();
    users.dispose();
  }
}

