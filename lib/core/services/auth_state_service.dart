import 'package:firebase_auth/firebase_auth.dart';
import 'package:partiu/common/state/app_state.dart';

/// Serviço para gerenciar estado de autenticação e modo convidado (guest)
/// 
/// CONTEXTO: Implementado para compliance com Apple App Store
/// Requisito: Permitir navegação sem cadastro, com login apenas para interações
/// 
/// ATUALIZADO: Agora usa AppState como fonte de verdade (sincronizado com SessionManager/AuthSyncService)
class AuthStateService {
  
  AuthStateService._();
  // Singleton pattern
  static AuthStateService? _instance;
  static AuthStateService get instance => _instance ??= AuthStateService._();

  /// Verifica se o usuário está navegando como convidado (não autenticado)
  /// USA AppState como fonte de verdade
  bool get isGuest => !AppState.isLoggedIn;

  /// Verifica se o usuário está autenticado
  /// USA AppState como fonte de verdade
  bool get isAuthenticated => AppState.isLoggedIn;

  /// Retorna o ID do usuário autenticado, ou null se guest
  /// USA AppState como fonte de verdade
  String? get userId => AppState.currentUserId;

  /// Retorna o email do usuário autenticado, ou null se guest
  /// Fallback para FirebaseAuth se AppState não tiver email
  String? get userEmail => FirebaseAuth.instance.currentUser?.email;

  /// Stream que emite mudanças no estado de autenticação
  Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();

  /// Verifica se o usuário atual tem permissões para uma ação
  /// Retorna true se autenticado, false se guest
  bool hasPermissionFor(String action) {
    // Guest não tem permissão para ações interativas
    if (isGuest) return false;
    
    // Usuário autenticado tem permissão por padrão
    // Adicione lógica extra aqui se necessário (ex: verificar role, subscription, etc.)
    return true;
  }

  /// Lista de ações que requerem autenticação
  static const List<String> restrictedActions = [
    'message',
    'edit_profile',
    'view_conversations',
    'view_notifications',
 
  ];

  /// Verifica se uma ação específica está restrita para guests
  bool isActionRestricted(String action) {
    return restrictedActions.contains(action);
  }
}
