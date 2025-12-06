import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/models/user.dart' as app_user;
import 'package:partiu/core/managers/session_manager.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/shared/repositories/user_repository.dart';
import 'package:partiu/common/services/notifications_counter_service.dart';

/// Serviço de orquestração de autenticação que trabalha COM SessionManager.
/// 
/// Segue o padrão do Advanced-Dating:
/// - Escuta Firebase Auth
/// - Carrega dados do Firestore
/// - Salva no SessionManager (fonte de verdade)
/// - SessionManager sincroniza automaticamente com AppState
class AuthSyncService extends ChangeNotifier {
  bool _initialized = false;
  StreamSubscription<fire_auth.User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  /// Usuário do Firebase Auth (delegado)
  fire_auth.User? get firebaseUser => fire_auth.FirebaseAuth.instance.currentUser;
  
  /// Usuário completo da aplicação (delegado para SessionManager)
  app_user.User? get appUser => SessionManager.instance.currentUser;
  
  /// Indica se o serviço foi inicializado (recebeu primeiro evento do Firebase)
  bool get initialized => _initialized;
  
  /// Indica se o usuário está logado (delegado para SessionManager)
  bool get isLoggedIn => SessionManager.instance.isLoggedIn && SessionManager.instance.currentUser != null;
  
  /// ID do usuário logado (delegado para AppState)
  String? get userId => AppState.currentUserId;

  AuthSyncService() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _log('🔄 Inicializando AuthSyncService');
    
    // Carregar usuário inicial do SessionManager se existir
    final sessionUser = SessionManager.instance.currentUser;
    if (sessionUser != null) {
      _log('📱 Usuário encontrado no SessionManager: ${sessionUser.userId}');
    }
    
    // Escuta mudanças no Firebase Auth
    _authSubscription = fire_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen(_handleAuthStateChange);
  }

  Future<void> _handleAuthStateChange(fire_auth.User? user) async {
    try {
      _log('🔄 Auth state changed: ${user?.uid ?? 'null'}');

      // Cancela subscription anterior do usuário se existir
      await _userSubscription?.cancel();
      _userSubscription = null;

      if (user != null) {
        // Usuário logado - carregar dados completos do Firestore e salvar no SessionManager
        _log('✅ Usuário logado, carregando dados do Firestore: ${user.uid}');
        await _loadUserDataAndSaveToSession(user.uid);
        
        // Inicializar contadores de notificações
        NotificationsCounterService.instance.initialize();
      } else {
        // Usuário deslogado - limpar SessionManager (que limpa AppState automaticamente)
        _log('🚪 Usuário deslogado, limpando SessionManager');
        await SessionManager.instance.logout();
        
        // Resetar contadores de notificações
        NotificationsCounterService.instance.reset();
      }

      // Marca como inicializado após o primeiro evento
      if (!_initialized) {
        _initialized = true;
        _log('✅ AuthSyncService inicializado');
      }

      // Notifica listeners (GoRouter, widgets, etc.)
      notifyListeners();
    } catch (e, stack) {
      _logError('❌ Erro ao processar mudança de auth', e, stack);
      
      // Mesmo com erro, marca como inicializado para não travar a UI
      if (!_initialized) {
        _initialized = true;
        notifyListeners();
      }
    }
  }

  /// Carrega dados do usuário do Firestore e salva no SessionManager (padrão Advanced-Dating)
  Future<void> _loadUserDataAndSaveToSession(String uid) async {
    try {
        _log('Carregando dados do usuário do Firestore: $uid');      // Escuta atualizações do Firestore em tempo real
      _userSubscription = FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .snapshots()
          .listen((snapshot) async {
        try {
          if (!snapshot.exists) {
            _log('Documento do usuário não existe: $uid');
            await SessionManager.instance.logout();
            return;
          }

          final data = snapshot.data();
          if (data == null) {
            _log('Dados do usuário são null: $uid');
            await SessionManager.instance.logout();
            return;
          }

          // CORREÇÃO: Garantir que o documento tem o campo userId
          if (!data.containsKey('userId') && uid.isNotEmpty) {
            data['userId'] = uid;
          }
          
          final user = app_user.User.fromDocument(data);
          _log('✅ Dados carregados do Firestore, salvando no SessionManager: ${user.userId}');
          
          // CHAVE: Salvar no SessionManager - ele sincroniza automaticamente com AppState
          await SessionManager.instance.login(user);
          
          _log('✅ Usuário salvo no SessionManager - AppState.currentUserId: ${AppState.currentUserId}');
          
          notifyListeners();
        } catch (e, stack) {
          _logError('Erro ao processar snapshot do usuário', e, stack);
        }
      });
    } catch (e, stack) {
      _logError('Erro ao carregar dados do usuário', e, stack);
    }
  }



  /// Força logout do usuário (delega para SessionManager)
  Future<void> signOut() async {
    try {
      _log('Iniciando logout via AuthSyncService');
      
      // Cancela subscriptions
      await _userSubscription?.cancel();
      _userSubscription = null;
      
      // Limpar cache do UserRepository
      UserRepository.clearCache();
      
      // SessionManager.logout() limpa tudo (AppState incluído)
      await SessionManager.instance.logout();
      
      // Firebase signOut por último (dispara authStateChanges que confirma o logout)
      await fire_auth.FirebaseAuth.instance.signOut();
      
      _log('Logout completado');
    } catch (e, stack) {
      _logError('Erro durante logout', e, stack);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  void _log(String message) {
    developer.log(message, name: 'partiu.auth_sync');
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'partiu.auth_sync',
      error: error,
      stackTrace: stackTrace,
    );
  }
}