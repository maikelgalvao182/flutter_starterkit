import 'package:flutter/material.dart';
import 'package:partiu/shared/models/user_model.dart';
import 'package:partiu/shared/repositories/user_repository.dart';
import 'package:partiu/shared/stores/user_store.dart';
import 'package:partiu/features/home/presentation/services/geo_service.dart';
import 'package:partiu/core/utils/app_logger.dart';

class NearbyButtonController extends ChangeNotifier {
  static final NearbyButtonController _instance = NearbyButtonController._internal();
  factory NearbyButtonController() => _instance;

  final UserRepository _userRepo;
  final GeoService _geoService;

  UserModel? recentUser;
  int nearbyCount = 0;
  bool isLoading = false;

  bool _hasLoaded = false;
  Future<void>? _inFlight;

  NearbyButtonController._internal({
    UserRepository? userRepo,
    GeoService? geoService,
  }) : 
    _userRepo = userRepo ?? UserRepository(),
    _geoService = geoService ?? GeoService();

  Future<void> loadData() async {
    if (_hasLoaded) {
      return;
    }
    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }

    isLoading = true;
    notifyListeners();

    final future = _loadDataInternal();
    _inFlight = future;
    return future;
  }

  Future<void> _loadDataInternal() async {
    try {
      // 1. Carrega usuário mais recente
      recentUser = await _userRepo.getMostRecentUser();

      // ✅ PRELOAD: Carregar avatar antes da UI renderizar
      final photoUrl = recentUser?.photoUrl;
      if (recentUser != null && photoUrl != null && photoUrl.isNotEmpty) {
        UserStore.instance.preloadAvatar(recentUser!.userId, photoUrl);
      }

      // ✅ Atualiza UI imediatamente com o usuário recente (não esperar geo)
      notifyListeners();

      // 2. Carrega contagem de usuários próximos (30km)
      final location = await _geoService.getCurrentUserLocation();
      if (location != null) {
        nearbyCount = await _geoService.countUsersWithin30Km(
          location.lat,
          location.lng,
        );
      }

      _hasLoaded = true;
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Erro ao carregar dados do PeopleButton (NearbyButtonController): $e',
        tag: 'PEOPLE_BUTTON',
      );
      if (AppLogger.verbose) {
        AppLogger.error(
          'StackTrace PeopleButton loadData',
          tag: 'PEOPLE_BUTTON',
          error: e,
          stackTrace: stackTrace,
        );
      }
    } finally {
      isLoading = false;
      _inFlight = null;
      notifyListeners();
    }
  }
}
