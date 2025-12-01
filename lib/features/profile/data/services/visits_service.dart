/// Serviço para gerenciar visitas do perfil
class VisitsService {
  VisitsService._();
  
  static final VisitsService _instance = VisitsService._();
  static VisitsService get instance => _instance;

  /// Cache do número de visitas
  int get cachedVisitsCount => 0;

  /// Stream para observar o número de visitas de um usuário
  Stream<int> watchUserVisitsCount(String userId) {
    // TODO: Implementar stream real com Firebase
    // Por agora, retorna stream com valor fixo
    return Stream.value(0);
  }
}