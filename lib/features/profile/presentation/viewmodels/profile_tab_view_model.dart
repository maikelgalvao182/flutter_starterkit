import 'package:flutter/material.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/services/auth_state_service.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/features/profile/data/services/profile_completeness_prompt_service.dart';
import 'package:partiu/core/managers/session_manager.dart';

/// Command para navegação - isola BuildContext do ViewModel
/// Retorna dados necessários para navegação sem depender de contexto
abstract class NavigationCommand {}

/// Command: Navegar para visualização de perfil
class ViewProfileCommand extends NavigationCommand {
  ViewProfileCommand(this.user);
  final User user;
}

/// Command: Navegar para edição de perfil
class EditProfileCommand extends NavigationCommand {
  EditProfileCommand();
}

/// Command: Mostrar diálogo de completude do perfil
class ShowCompletenessDialogCommand extends NavigationCommand {
  ShowCompletenessDialogCommand();
}

/// ViewModel para ProfileTab seguindo padrão MVVM
/// Gerencia estado e lógica de negócio da tab de perfil
/// 
/// Responsabilidades:
/// - Expor estado do usuário atual
/// - Gerenciar comandos de navegação (retorna Commands)
/// - Controlar exibição de diálogos
/// - Isolar lógica de negócio da UI
/// 
/// Melhorias implementadas:
/// - [OK] Injeção de dependência explícita
/// - [OK] Commands sem BuildContext
/// - [OK] Testabilidade aprimorada
class ProfileTabViewModel extends ChangeNotifier {

  // ==================== LIFECYCLE ====================
  
  /// Construtor com injeção de dependência
  /// Permite passar mocks para testes
  ProfileTabViewModel({
    ValueNotifier<User?>? userNotifier,
    ProfileCompletenessPromptService? promptService,
  })  : _userNotifier = userNotifier ?? AppState.currentUser,
        _promptService = promptService ?? ProfileCompletenessPromptService.instance {
    // Escuta mudanças no estado do usuário
    _userNotifier.addListener(_onUserChanged);
    
    // Tenta restaurar usuário se estiver nulo (ex: após hot reload)
    _restoreUserIfNeeded();
  }
  // ==================== DEPENDENCIES ====================
  
  final ValueNotifier<User?> _userNotifier;
  final ProfileCompletenessPromptService _promptService;
  
  // ==================== STATE ====================
  
  /// Usuário atual observável
  User? get currentUser => _userNotifier.value;
  
  /// ID do usuário atual
  String? get currentUserId => currentUser?.userId;
  
  /// Verifica se usuário está autenticado
  /// Combina Firebase Auth (fonte da verdade) com AppState (cache local)
  /// para evitar falsos negativos durante inicialização ou hot reload
  bool get isAuthenticated {
    // 1. Se Firebase diz que está logado, está logado.
    if (AuthStateService.instance.isAuthenticated) return true;
    
    // 2. Se temos um usuário válido no estado/sessão, consideramos logado
    // Isso cobre o gap entre inicialização do app e restauração do Firebase
    final user = currentUser;
    return user != null && user.userId.isNotEmpty;
  }
  
  /// Verifica se dados do usuário estão carregados
  bool get isUserDataLoaded {
    final user = currentUser;
    return user != null && user.userId.isNotEmpty && user.userFullname.isNotEmpty;
  }
  
  /// Tenta restaurar o usuário do SessionManager se o estado estiver vazio
  void _restoreUserIfNeeded() {
    if (_userNotifier.value == null) {
      final sessionUser = SessionManager.instance.currentUser;
      if (sessionUser != null) {
        // Atualiza o notifier (que é o AppState.currentUser por padrão)
        _userNotifier.value = sessionUser;
        notifyListeners();
      }
    }
  }
  
  /// Calcula completeness de forma síncrona e reativa
  /// Delega ao service para manter a lógica centralizada
  int calculateCompletenessPercentage() {
    final user = currentUser;
    if (user == null) return 0;
    
    return _promptService.calculateCompletenessSync(user);
  }

  @override
  void dispose() {
    _userNotifier.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    notifyListeners();
  }

  // ==================== COMMANDS ====================
  
  /// Command: Preparar navegação para tela de visualização de perfil
  /// Retorna command se navegação for válida, null caso contrário
  /// View é responsável por executar a navegação com BuildContext
  ViewProfileCommand? prepareViewProfileNavigation() {
    
    if (!isAuthenticated) {
      return null;
    }
    
    // Se currentUser for null mas AppState tiver userId, ainda permite navegação
    // A tela de perfil vai buscar os dados necessários
    final user = currentUser;
    if (user == null) {
      return null;
    }
    
    return ViewProfileCommand(user);
  }
  
  /// Command: Preparar navegação para tela de edição de perfil
  /// Retorna command se navegação for válida, null caso contrário
  /// View é responsável por executar a navegação com BuildContext
  EditProfileCommand? prepareEditProfileNavigation() {
    
    // Usa isAuthenticated que já faz fallback para AppState
    if (!isAuthenticated) {
      return null;
    }
    
    return EditProfileCommand();
  }
  
  /// Command: Preparar diálogo de completude do perfil
  /// Retorna command se deve mostrar, null caso contrário
  ShowCompletenessDialogCommand? prepareCompletenessDialog() {
    // Skip para usuários não autenticados
    if (!isAuthenticated) {
      return null;
    }
    
    return ShowCompletenessDialogCommand();
  }
  
  // ==================== ASYNC OPERATIONS ====================
  
  /// Verifica se deve exibir diálogo de completude
  /// [OK] Método sem BuildContext - apenas retorna bool
  bool shouldCheckCompleteness() {
    return isAuthenticated;
  }
  
  /// Executa verificação de completude do perfil (async)
  /// View deve passar BuildContext quando executar
  Future<void> executeCompletenessCheck(BuildContext context) async {
    try {
      await _promptService.maybeShow(context: context);
    } catch (e) {
      // Silencia erros de imagem/UI para não quebrar UX
    }
  }
}