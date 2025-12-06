import 'package:partiu/features/profile/data/services/profile_visits_service.dart';

/// Serviço para gerenciar visitas do perfil
class VisitsService {
  VisitsService._();
  
  static final VisitsService _instance = VisitsService._();
  static VisitsService get instance => _instance;

  /// Cache do número de visitas
  int get cachedVisitsCount => 0;

  /// Stream para observar o número de visitas de um usuário
  Stream<int> watchUserVisitsCount(String userId) {
    return ProfileVisitsService.instance.watchVisitsCount(userId);
  }
}