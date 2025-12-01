import 'package:partiu/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

/// ViewModel para gerenciar estado da tela EmailAuthScreen
/// 
/// Responsabilidades:
/// - Controlar modo (Login vs Cadastro)
/// - Gerenciar estados de loading e visibilidade de senha
/// - Expor estado reativo via ChangeNotifier
class EmailAuthViewModel extends ChangeNotifier {
  static const _tag = 'EmailAuthViewModel';

  // ===========================
  // ESTADOS INTERNOS
  // ===========================
  
  bool _isLogin = true; // true = Login, false = Cadastro
  bool _obscurePassword = true;
  bool _isLoading = false;

  // ===========================
  // GETTERS
  // ===========================
  
  /// Se está em modo Login (true) ou Cadastro (false)
  bool get isLogin => _isLogin;
  
  /// Se a senha deve estar oculta
  bool get obscurePassword => _obscurePassword;
  
  /// Se está processando uma requisição
  bool get isLoading => _isLoading;

  // ===========================
  // ACTIONS
  // ===========================

  /// Alterna entre modo Login e Cadastro
  void toggleMode() {
    _isLogin = !_isLogin;
    AppLogger.info('Modo alterado para: ${_isLogin ? "Login" : "Cadastro"}', tag: _tag);
    notifyListeners();
  }

  /// Alterna visibilidade da senha
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Define estado de loading
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      AppLogger.info('Loading state: $loading', tag: _tag);
      notifyListeners();
    }
  }

  /// Reseta o estado inicial (útil ao voltar para a tela)
  void reset() {
    _isLogin = true;
    _obscurePassword = true;
    _isLoading = false;
    AppLogger.info('Estado resetado', tag: _tag);
    notifyListeners();
  }

  @override
  void dispose() {
    AppLogger.info('EmailAuthViewModel disposed', tag: _tag);
    super.dispose();
  }
}
