import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart' as fire_auth;
import 'package:partiu/core/managers/session_manager.dart';
import 'package:partiu/core/services/session_cleanup_service.dart';

/// Serviço especializado em proteger o estado de autenticação durante hot reloads.
/// 
/// Durante o desenvolvimento, o hot reload pode causar:
/// 1. Firebase Auth emitir null temporariamente
/// 2. Listeners sendo re-criados
/// 3. Estado reativo sendo resetado
/// 
/// Este serviço implementa estratégias para manter a sessão estável.
class HotReloadProtectionService {
  HotReloadProtectionService._();
  
  static final HotReloadProtectionService _instance = HotReloadProtectionService._();
  static HotReloadProtectionService get instance => _instance;
  
  Timer? _graceTimer;
  bool _isInGracePeriod = false;
  
  /// Período de graça após receber null do Firebase Auth
  static const Duration gracePeriod = Duration(seconds: 3);
  
  /// Indica se estamos em período de graça (protegendo contra hot reload)
  bool get isInGracePeriod => _isInGracePeriod;
  
  /// Inicia período de proteção quando Firebase Auth emite null
  void startGracePeriod() {
    if (_isInGracePeriod) return;
    
    _log('Iniciando período de proteção contra hot reload');
    _isInGracePeriod = true;
    
    // Cancela timer anterior se existir
    _graceTimer?.cancel();
    
    // Agenda fim do período de graça
    _graceTimer = Timer(gracePeriod, () {
      _log('Fim do período de proteção');
      _isInGracePeriod = false;
    });
  }
  
  /// Cancela período de proteção (usuário autenticou novamente)
  void cancelGracePeriod() {
    if (!_isInGracePeriod) return;
    
    _log('Cancelando período de proteção - usuário autenticado');
    _graceTimer?.cancel();
    _isInGracePeriod = false;
  }
  
  /// Verifica se deve manter sessão local durante null do Firebase
  bool shouldPreserveLocalSession() {
    // Se estamos fazendo logout explícito, não preserva
    if (SessionCleanupService.isLoggingOut) {
      return false;
    }
    
    // Se temos usuário na sessão local e estamos em período de graça
    final hasLocalUser = SessionManager.instance.currentUser != null;
    final shouldPreserve = hasLocalUser && _isInGracePeriod;
    
    if (shouldPreserve) {
      _log('Preservando sessão local durante hot reload');
    }
    
    return shouldPreserve;
  }
  
  /// Sincroniza estado após Firebase restaurar sessão
  Future<void> syncSessionState() async {
    try {
      final firebaseUser = fire_auth.FirebaseAuth.instance.currentUser;
      final sessionUser = SessionManager.instance.currentUser;
      
      _log('Sincronizando estado - Firebase: ${firebaseUser?.uid}, Local: ${sessionUser?.userId}');
      
      // Se Firebase não tem usuário mas SessionManager tem
      if (firebaseUser == null && sessionUser != null) {
        // Se não estamos em logout explícito, pode ser inconsistência
        if (!SessionCleanupService.isLoggingOut) {
          _log('Detectada inconsistência: Firebase null mas sessão local existe');
          
          // Aguarda um pouco para ver se Firebase se recupera
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Verifica novamente
          final updatedFirebaseUser = fire_auth.FirebaseAuth.instance.currentUser;
          if (updatedFirebaseUser == null) {
            _log('Firebase ainda null após delay - limpando sessão local');
            await SessionManager.instance.logout();
          }
        }
      }
      
      // Se Firebase tem usuário mas SessionManager não
      if (firebaseUser != null && sessionUser == null) {
        _log('Firebase tem usuário mas sessão local vazia - isso será resolvido pelo userStream');
      }
      
      // Se ambos têm usuários diferentes
      if (firebaseUser != null && 
          sessionUser != null && 
          firebaseUser.uid != sessionUser.userId) {
        _log('UIDs diferentes - Firebase: ${firebaseUser.uid}, Local: ${sessionUser.userId}');
        _log('Deixando userStream resolver a divergência');
      }
      
    } catch (e, stack) {
      _logError('Erro ao sincronizar estado da sessão', e, stack);
    }
  }
  
  /// Dispose do serviço
  void dispose() {
    _graceTimer?.cancel();
    _isInGracePeriod = false;
  }
  
  void _log(String message) {
    developer.log(message, name: 'partiu.hot_reload_protection');
  }
  
  void _logError(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'partiu.hot_reload_protection',
      error: error,
      stackTrace: stackTrace,
    );
  }
}