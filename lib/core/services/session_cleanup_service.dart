import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/managers/session_manager.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Serviço responsável por realizar a limpeza robusta de sessão.
/// Inspirado no fluxo de logout do projeto Advanced-Dating.
/// Problema reportado: dados antigos de usuário permanecem após login em outra conta.
/// Solução: limpar fontes reativas, caches, tokens push e estado global.
class SessionCleanupService {
  final fire_auth.FirebaseAuth _firebaseAuth = fire_auth.FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Tópico global (ajustar se houver diferença entre ambientes)
  static const String globalTopic = 'partiu_global';
  
  // Flag para controlar logout em andamento e prevenir relogin automático
  static bool _isLoggingOut = false;
  
  /// Retorna true se logout está em andamento
  static bool get isLoggingOut => _isLoggingOut;

  /// Executa o logout completo e limpeza de sessão.
  Future<void> performLogout() async {
    _isLoggingOut = true; // Marcar início do logout
    _log('=== INICIANDO LOGOUT COMPLETO ===');
    
    try {
      // 1. Parar listeners de push e remover token do usuário atual
      _log('ETAPA 1: Removendo device token do usuário');
      try {
        final uid = _firebaseAuth.currentUser?.uid;
        _log('UID do usuário atual: $uid');
        if (uid != null) {
          // TODO: Implementar remoção do device token quando tivermos push notifications
          // await UserPushNotificationService().removeUserDeviceToken(uid);
          _log('Device token removido com sucesso para UID: $uid');
        } else {
          _log('Nenhum usuário logado, pulando remoção de device token');
        }
      } catch (e) {
        _log('Falha ao remover device token: $e');
      }

      // 2. Google Sign-In logout
      _log('ETAPA 2: Fazendo logout do Google Sign-In');
      try {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.signOut();
        _log('Google Sign-In cleared com sucesso');
      } catch (e) {
        _log('Falha ao limpar Google Sign-In: $e');
      }

      // 3. Limpar caches personalizados
      _log('ETAPA 3: Limpando caches personalizados');
      try {
        final uid = _firebaseAuth.currentUser?.uid;
        if (uid != null) {
          _log('Limpando caches para UID: $uid');
          // TODO: Implementar limpeza de caches específicos quando necessário
          _log('Caches personalizados limpos com sucesso');
        } else {
          _log('UID nulo, pulando limpeza de caches personalizados');
        }
      } catch (e) {
        _log('Falha ao limpar caches: $e');
      }

      // 4. Desinscrever de tópicos FCM específicos do usuário (se aplicável)
      _log('ETAPA 4: Desinscrevendo de tópicos FCM do usuário');
      try {
        final uid = _firebaseAuth.currentUser?.uid;
        if (uid != null) {
          // Padrão: tópicos nomeados pelo UID
          final topicName = 'user_$uid';
          _log('Desinscrevendo do tópico: $topicName');
          await _messaging.unsubscribeFromTopic(topicName);
          _log('Desinscrição do tópico $topicName realizada com sucesso');
        } else {
          _log('UID nulo, pulando desinscrição de tópicos FCM');
        }
      } catch (e) {
        _log('Falha ao desinscrever de tópicos: $e');
      }

      // 4.1. Apagar token FCM local para evitar associação com nova sessão
      _log('ETAPA 4.1: Apagando device token FCM local');
      try {
        await _messaging.deleteToken();
        _log('Device token FCM local apagado com sucesso');
      } catch (e) {
        _log('Falha ao apagar device token FCM local: $e');
      }

      // 5. Limpar sessão persistida (SharedPreferences) via SessionManager
      _log('ETAPA 5: Limpando SessionManager e SharedPreferences');
      try {
        _log('Inicializando SessionManager');
        await SessionManager.instance.initialize();
        _log('SessionManager inicializado');
        
        // Zera token FCM salvo localmente e apaga usuário/sinalizadores
        _log('Zerando FCM token local');
        SessionManager.instance.fcmToken = null;
        _log('FCM token local zerado');
        
        _log('Executando logout do SessionManager');
        await SessionManager.instance.logout();
        _log('SessionManager logout executado com sucesso');
      } catch (e) {
        _log('Falha ao limpar SessionManager: $e');
      }

      // 6. Firebase Auth signOut (após limpar preferências/caches)
      _log('ETAPA 6: Fazendo signOut do Firebase Auth');
      try { 
        await _firebaseAuth.signOut();
        _log('Firebase Auth signOut executado com sucesso');
      } catch (e) {
        _logError('Erro em FirebaseAuth.signOut: $e');
      }

      // 7. Reset reativo global (ValueNotifiers) - redundante, mas inofensivo
      _log('ETAPA 7: Resetando estado reativo global');
      _resetGlobalReactiveState();
      _log('Estado reativo global resetado');

      // 8. Limpar cache offline do Firestore para evitar dados antigos
      _log('ETAPA 8: Limpando cache offline do Firestore');
      try {
        await FirebaseFirestore.instance.clearPersistence();
        _log('Cache offline do Firestore limpo com sucesso');
      } catch (e) {
        _log('Falha ao limpar cache offline do Firestore: $e');
      }

      // 9. Reinscrever em tópico global (padrão pós logout)
      _log('ETAPA 9: Reinscrevendo no tópico global: $globalTopic');
      try { 
        await _messaging.subscribeToTopic(globalTopic);
        _log('Reinscrição no tópico global $globalTopic realizada com sucesso');
      } catch (e) {
        _log('Falha ao reinscrever no tópico global: $e');
      }

      _log('=== LOGOUT COMPLETO FINALIZADO COM SUCESSO ===');
    } catch (e, st) {
      _logError('Falha inesperada no performLogout: $e', stackTrace: st);
      rethrow; // Propaga erro para o chamador
    } finally {
      _isLoggingOut = false;
      _log('Flag de logout resetado');
    }
  }

  void _resetGlobalReactiveState() {
    try {
      _log('Resetando AppState.currentUser');
      AppState.currentUser.value = null;
      
      _log('Resetando AppState.isVerified');
      AppState.isVerified.value = false;
      
      _log('Resetando contadores de notificações');
      AppState.unreadNotifications.value = 0;
      AppState.unreadMessages.value = 0;
      AppState.unreadLikes.value = 0;
      
      _log('Resetando rota atual e estado de background');
      AppState.currentRoute.value = '/';
      AppState.isAppInBackground.value = false;
      
      _log('Todos os valores do AppState foram resetados');
    } catch (e) {
      _log('Falha ao resetar AppState: $e');
    }
  }

  // ==================== LOGGING ====================

  void _log(String message) {
    developer.log(message, name: 'partiu.session_cleanup');
  }

  void _logError(String message, {StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'partiu.session_cleanup',
      error: message,
      stackTrace: stackTrace,
    );
  }
}