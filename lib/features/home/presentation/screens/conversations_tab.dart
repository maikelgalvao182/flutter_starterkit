import 'package:flutter/material.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';

/// Tela de conversas (Tab 3)
/// TODO: Implementar funcionalidade de conversas
class ConversationsTab extends StatelessWidget {
  const ConversationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: GlimpseEmptyState.conversations(
          text: 'Nenhuma conversa ainda\nImplementar funcionalidade de conversas',
        ),
      ),
    );
  }
}
