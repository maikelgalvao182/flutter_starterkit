import 'package:flutter/foundation.dart';

/// Interface para repositório de autenticação
abstract class IAuthRepository {
  Future<void> authUserAccount({
    required VoidCallback updateLocationScreen,
    required VoidCallback signUpScreen,
    required VoidCallback homeScreen,
    required VoidCallback blockedScreen,
  });

  Future<void> signInWithGoogle({
    required VoidCallback checkUserAccount,
    required Function(dynamic) onError,
    Function(String)? onNameReceived,
  });

  Future<void> signInWithApple({
    required VoidCallback checkUserAccount,
    required VoidCallback onNotAvailable,
    required Function(dynamic) onError,
    Function(String)? onNameReceived,
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
    required VoidCallback checkUserAccount,
    required Function(dynamic) onError,
  });

  Future<void> createUserWithEmail({
    required String email,
    required String password,
    required VoidCallback checkUserAccount,
    required Function(dynamic) onError,
  });
}
