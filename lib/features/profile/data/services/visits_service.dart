import 'package:partiu/features/profile/data/services/profile_visits_service.dart';

/// Serviço para gerenciar visitas do perfil
class VisitsService {
  VisitsService._();
  
  static final VisitsService _instance = VisitsService._();
  static VisitsService get instance => _instance;

  /// Cache do número de visitas
  int get cachedVisitsCount => 0;

  /// Busca o número de visitas de um usuário
  Future<int> getUserVisitsCount(String userId) {
    return ProfileVisitsService.instance.getVisitsCount(userId);
  }

  /// Stream simplificado para observar o número de visitas
  /// Retorna stream que emite o count sempre que a lista de visitors muda
  Stream<int> watchUserVisitsCount(String userId) async* {
    // Emitir count inicial
    yield await getUserVisitsCount(userId);
    
    // Escutar mudanças no stream de visitors e emitir novo count
    await for (final visitors in ProfileVisitsService.instance.visitsStream) {
      yield visitors.length;
    }
  }
}