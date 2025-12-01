import 'package:flutter/material.dart';
import 'package:partiu/common/state/app_state.dart';

/// ViewModel para gerenciar a seção de app/configurações
class AppSectionViewModel extends ChangeNotifier {
  
  /// Faz logout do usuário
  Future<void> signOut() async {
    try {
      // TODO: Implementar logout real com Firebase Auth
      // Por agora, apenas limpa o estado local
      await AppState.signOut();
    } catch (e) {
      // Log error but don't rethrow to avoid breaking UI
      debugPrint('Error during sign out: $e');
    }
  }
}