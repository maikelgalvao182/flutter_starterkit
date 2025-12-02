import 'package:flutter/material.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';

/// Tela de descoberta (Tab 0)
/// TODO: Implementar funcionalidade de descoberta
class DiscoverTab extends StatelessWidget {
  const DiscoverTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: GlimpseEmptyState.standard(
          text: 'Nenhum usuário encontrado\nImplementar funcionalidade de descoberta',
        ),
      ),
    );
  }
}
