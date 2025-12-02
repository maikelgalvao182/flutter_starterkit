import 'package:flutter/material.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/services/session_cleanup_service.dart';

/// ViewModel para gerenciar a seção de app/configurações
class AppSectionViewModel extends ChangeNotifier {
  
  /// Faz logout do usuário
  Future<void> signOut() async {
    try {
      // Usa SessionCleanupService para logout robusto
      final sessionCleanupService = SessionCleanupService();
      await sessionCleanupService.performLogout();
    } catch (e) {
      // Log error but don't rethrow to avoid breaking UI
      debugPrint('Error during sign out: $e');
      // Fallback para reset básico
      await AppState.signOut();
    }
  }
}