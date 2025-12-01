import 'package:partiu/shared/repositories/auth_repository_interface.dart';
import 'package:flutter/material.dart';

/// ViewModel para a tela de login
class SignInViewModel extends ChangeNotifier {

  SignInViewModel({required IAuthRepository authRepository})
      : _authRepository = authRepository;
  final IAuthRepository _authRepository;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Autentica o usuário com base no estado atual
  Future<void> authUserAccount({
    required VoidCallback updateLocationScreen,
    required VoidCallback signUpScreen,
    required VoidCallback homeScreen,
    required VoidCallback blockedScreen,
  }) async {
    _setLoading(true);
    
    try {
      await _authRepository.authUserAccount(
        updateLocationScreen: updateLocationScreen,
        signUpScreen: signUpScreen,
        homeScreen: homeScreen,
        blockedScreen: blockedScreen,
      );
    } catch (e) {
      // Ignore authentication errors - handled by repository
    } finally {
      _setLoading(false);
    }
  }

  /// Faz login com Google
  Future<void> signInWithGoogle({
    required VoidCallback checkUserAccount,
    required Function(dynamic) onError,
    Function(String)? onNameReceived,
  }) async {
    _setLoading(true);
    
    try {
      await _authRepository.signInWithGoogle(
        checkUserAccount: checkUserAccount,
        onError: onError,
        onNameReceived: onNameReceived,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Faz login com Apple
  Future<void> signInWithApple({
    required VoidCallback checkUserAccount,
    required VoidCallback onNotAvailable,
    required Function(dynamic) onError,
    Function(String)? onNameReceived,
  }) async {
    _setLoading(true);
    
    try {
      await _authRepository.signInWithApple(
        checkUserAccount: checkUserAccount,
        onNotAvailable: onNotAvailable,
        onError: onError,
        onNameReceived: onNameReceived,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Faz login com Email/Senha
  Future<void> signInWithEmail({
    required String email,
    required String password,
    required VoidCallback checkUserAccount,
    required Function(dynamic) onError,
  }) async {
    _setLoading(true);
    
    try {
      await _authRepository.signInWithEmail(
        email: email,
        password: password,
        checkUserAccount: checkUserAccount,
        onError: onError,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Cria conta com Email/Senha
  Future<void> createUserWithEmail({
    required String email,
    required String password,
    required VoidCallback checkUserAccount,
    required Function(dynamic) onError,
  }) async {
    _setLoading(true);
    
    try {
      await _authRepository.createUserWithEmail(
        email: email,
        password: password,
        checkUserAccount: checkUserAccount,
        onError: onError,
      );
    } finally {
      _setLoading(false);
    }
  }
}
