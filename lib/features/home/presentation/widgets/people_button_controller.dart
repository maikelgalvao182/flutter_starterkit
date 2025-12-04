import 'package:flutter/material.dart';
import 'package:partiu/shared/models/user_model.dart';
import 'package:partiu/shared/repositories/user_repository.dart';
import 'package:partiu/features/home/presentation/services/geo_service.dart';

class NearbyButtonController extends ChangeNotifier {
  final UserRepository _userRepo;
  final GeoService _geoService;

  UserModel? recentUser;
  int nearbyCount = 0;
  bool isLoading = false;

  NearbyButtonController({
    UserRepository? userRepo,
    GeoService? geoService,
  }) : 
    _userRepo = userRepo ?? UserRepository(),
    _geoService = geoService ?? GeoService();

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. Carrega usuário mais recente
      recentUser = await _userRepo.getMostRecentUser();

      // 2. Carrega contagem de usuários próximos (30km)
      final location = await _geoService.getCurrentUserLocation();
      if (location != null) {
        nearbyCount = await _geoService.countUsersWithin30Km(
          location.lat,
          location.lng,
        );
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do botão Perto de Você: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
