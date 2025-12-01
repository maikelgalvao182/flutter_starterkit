import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/shared/repositories/auth_repository_interface.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/shared/services/auth/social_auth.dart';

class AuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> authUserAccount({
    required VoidCallback updateLocationScreen,
    required VoidCallback signUpScreen,
    required VoidCallback homeScreen,
    required VoidCallback blockedScreen,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      
      if (user == null) {
        AppLogger.warning('No authenticated user found', tag: 'AUTH_REPOSITORY');
        signUpScreen();
        return;
      }

      AppLogger.info('Checking user profile for: ${user.uid}', tag: 'AUTH_REPOSITORY');

      // Tenta buscar o documento com retry para lidar com erros temporários
      DocumentSnapshot? userDoc;
      int retryCount = 0;
      const maxRetries = 3;
      const retryDelay = Duration(seconds: 2);

      while (retryCount < maxRetries) {
        try {
          userDoc = await _firestore.collection('Users').doc(user.uid).get();
          break; // Sucesso, sai do loop
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow; // Último retry falhou, propaga o erro
          }
          AppLogger.warning(
            'Firestore error (attempt $retryCount/$maxRetries): $e. Retrying...',
            tag: 'AUTH_REPOSITORY',
          );
          await Future.delayed(retryDelay);
        }
      }

      if (userDoc == null || !userDoc.exists) {
        AppLogger.info('User document not found - redirecting to signup wizard', tag: 'AUTH_REPOSITORY');
        signUpScreen();
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Verifica se o perfil está completo (tem nome e tipo de usuário)
      final hasFullName = userData['fullName'] != null && (userData['fullName'] as String).isNotEmpty;
      final hasUserType = userData['userType'] != null && (userData['userType'] as String).isNotEmpty;
      
      if (!hasFullName || !hasUserType) {
        AppLogger.info('User profile incomplete - redirecting to signup wizard', tag: 'AUTH_REPOSITORY');
        signUpScreen();
        return;
      }

      // Verifica se está bloqueado
      final isBlocked = userData['isBlocked'] == true;
      if (isBlocked) {
        AppLogger.warning('User is blocked', tag: 'AUTH_REPOSITORY');
        blockedScreen();
        return;
      }

      // Perfil completo - vai para home
      // NOTA: Removida verificação de localização - usuário pode adicionar depois
      AppLogger.success('User profile complete - redirecting to home', tag: 'AUTH_REPOSITORY');
      homeScreen();
    } catch (e) {
      AppLogger.error('Error checking user account: $e', tag: 'AUTH_REPOSITORY');
      // Em caso de erro, assume que é um novo usuário e vai para signup
      signUpScreen();
    }
  }

  @override
  Future<void> signInWithFacebook({
    required VoidCallback checkUserAccount,
    required Function(dynamic) onError,
  }) async {
    // TODO: Implementar Facebook Auth
    onError({'code': 'not-implemented', 'message': 'Facebook sign in not implemented yet'});
  }

  @override
  Future<void> signInWithGoogle({
    required VoidCallback checkUserAccount,
    required Function(dynamic) onError,
    Function(String)? onNameReceived,
  }) async {
    try {
      AppLogger.info('Starting Google Sign In', tag: 'AUTH_REPOSITORY');
      
      await SocialAuth.signInWithGoogle(
        checkUserAccount: () {
          AppLogger.success('Google Sign In successful', tag: 'AUTH_REPOSITORY');
          checkUserAccount();
        },
        onError: (FirebaseAuthException error) {
          AppLogger.error('Google Sign In error: ${error.code}', tag: 'AUTH_REPOSITORY');
          onError(error);
        },
        onNameReceived: onNameReceived,
      );
    } catch (e) {
      AppLogger.error('Google Sign In unexpected error: $e', tag: 'AUTH_REPOSITORY');
      onError({'code': 'unknown', 'message': e.toString()});
    }
  }

  @override
  Future<void> signInWithApple({
    required VoidCallback checkUserAccount,
    required VoidCallback onNotAvailable,
    required Function(dynamic) onError,
    Function(String)? onNameReceived,
  }) async {
    try {
      AppLogger.info('Starting Apple Sign In', tag: 'AUTH_REPOSITORY');
      
      await SocialAuth.signInWithApple(
        checkUserAccount: () {
          AppLogger.success('Apple Sign In successful', tag: 'AUTH_REPOSITORY');
          checkUserAccount();
        },
        onNotAvailable: () {
          AppLogger.warning('Apple Sign In not available', tag: 'AUTH_REPOSITORY');
          onNotAvailable();
        },
        onError: (FirebaseAuthException error) {
          AppLogger.error('Apple Sign In error: ${error.code}', tag: 'AUTH_REPOSITORY');
          onError(error);
        },
        onNameReceived: onNameReceived,
      );
    } catch (e) {
      AppLogger.error('Apple Sign In unexpected error: $e', tag: 'AUTH_REPOSITORY');
      onError({'code': 'unknown', 'message': e.toString()});
    }
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
    required VoidCallback checkUserAccount,
    required Function(dynamic) onError,
  }) async {
    try {
      AppLogger.info('Starting Email Sign In for: $email', tag: 'AUTH_REPOSITORY');
      
      await SocialAuth.signInWithEmail(
        email: email,
        password: password,
        checkUserAccount: () {
          AppLogger.success('Email Sign In successful', tag: 'AUTH_REPOSITORY');
          checkUserAccount();
        },
        onError: (FirebaseAuthException error) {
          AppLogger.error('Email Sign In error: ${error.code}', tag: 'AUTH_REPOSITORY');
          onError(error);
        },
      );
    } catch (e) {
      AppLogger.error('Email Sign In unexpected error: $e', tag: 'AUTH_REPOSITORY');
      onError({'code': 'unknown', 'message': e.toString()});
    }
  }

  @override
  Future<void> createUserWithEmail({
    required String email,
    required String password,
    required VoidCallback checkUserAccount,
    required Function(dynamic) onError,
  }) async {
    try {
      AppLogger.info('Creating user with email: $email', tag: 'AUTH_REPOSITORY');
      
      await SocialAuth.createUserWithEmail(
        email: email,
        password: password,
        checkUserAccount: () {
          AppLogger.success('User created successfully', tag: 'AUTH_REPOSITORY');
          checkUserAccount();
        },
        onError: (FirebaseAuthException error) {
          AppLogger.error('Create user error: ${error.code}', tag: 'AUTH_REPOSITORY');
          onError(error);
        },
      );
    } catch (e) {
      AppLogger.error('Create user unexpected error: $e', tag: 'AUTH_REPOSITORY');
      onError({'code': 'unknown', 'message': e.toString()});
    }
  }
}
