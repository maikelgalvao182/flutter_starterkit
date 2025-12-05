import 'package:partiu/core/services/session_cleanup_service.dart';

/// ViewModel para gerenciar a seção de app/configurações
class AppSectionViewModel {
  final SessionCleanupService _sessionCleanupService = SessionCleanupService();
  
  /// Faz logout do usuário usando processo robusto de 9 etapas
  /// 
  /// A navegação deve ser feita pelo widget que chama este método.
  /// Este método não lança exceções - erros são logados mas o processo continua.
  Future<void> signOut() async {
    await _sessionCleanupService.performLogout();
  }
}