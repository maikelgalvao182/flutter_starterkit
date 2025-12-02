import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/core/router/app_router.dart';


/// Router para navegação de perfil
/// Centraliza a navegação e decide qual versão da tela mostrar
class ProfileScreenRouter {
  
  /// Navegar para visualização de perfil
  static Future<void> navigateToProfile(
    BuildContext context, {
    required User user,
  }) async {
    final currentUserId = AppState.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      if (context.mounted) {
        _showError(context, 'Usuário não autenticado');
      }
      return;
    }

    context.push(
      AppRoutes.profile,
      extra: {
        'user': user,
        'currentUserId': currentUserId,
      },
    );
  }

  /// Navegar para edição de perfil
  static Future<void> navigateToEditProfile(BuildContext context) async {
    // Aguardar um frame para garantir que AppState foi atualizado
    await Future.delayed(Duration.zero);
    
    final currentUserId = AppState.currentUserId;
    
    // Aguardar até 3 frames adicionais se ainda estiver null
    if ((currentUserId == null || currentUserId.isEmpty) && context.mounted) {
      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final retryUserId = AppState.currentUserId;
        if (retryUserId != null && retryUserId.isNotEmpty) {
          break;
        }
      }
    }
    
    final finalUserId = AppState.currentUserId;
    
    if (finalUserId == null || finalUserId.isEmpty) {
      if (context.mounted) {
        _showError(context, 'Usuário não autenticado. Tente novamente.');
      }
      return;
    }

    // Usa go_router ao invés de Navigator direto
    if (context.mounted) {
      context.push(AppRoutes.editProfile);
    }
  }

  /// Navegar por ID do usuário (busca dados frescos)
  static Future<void> navigateByUserId(
    BuildContext context, {
    required String userId,
    bool forceRefresh = false,
  }) async {
    try {
      // TODO: Implementar busca de usuário por ID via serviço
      // Por agora, usa o usuário atual se for o mesmo ID
      final currentUser = AppState.currentUser.value;
      if (currentUser?.userId == userId) {
        await navigateToProfile(context, user: currentUser!);
        return;
      }
      
      // Se for outro usuário, mostra erro por enquanto
      if (context.mounted) {
        _showError(context, 'Visualização de outros perfis ainda não implementada');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Erro ao carregar perfil: $e');
      }
    }
  }

  /// Mostra erro via SnackBar
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}