import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:partiu/features/conversations/state/conversations_viewmodel.dart';

/// Serviço responsável pelo gerenciamento de estado e refresh das conversas
class ConversationStateService {
  const ConversationStateService();

  /// Executa refresh das conversações
  Future<void> refreshConversations(
    BuildContext context, {
    bool isRefresh = false,
  }) async {
    final viewModel = context.read<ConversationsViewModel>();
    if (viewModel.isRefreshing) return;

    if (isRefresh) {
      viewModel.setIsRefreshing(true);
    }

    try {
      // The stream will automatically refresh, so we just need to trigger a rebuild
      // No need to clear cache as conversations are real-time via stream

      // No forced setState needed - provider handles state
    } catch (e) {
      // Ignore refresh errors
    } finally {
      if (context.mounted && isRefresh) {
        viewModel.setIsRefreshing(false);
      }
    }
  }

  /// Reseta a paginação e executa refresh
  Future<void> resetAndRefresh(BuildContext context) async {
    final viewModel = context.read<ConversationsViewModel>();
    // Reset pagination and rely on stream to refill first page
    viewModel.resetPagination();
    await refreshConversations(context, isRefresh: true);
  }
}
