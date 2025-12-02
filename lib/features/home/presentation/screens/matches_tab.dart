import 'package:flutter/material.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';

/// Tela de matches (Tab 1)
/// TODO: Implementar funcionalidade de matches
class MatchesTab extends StatelessWidget {
  const MatchesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: GlimpseEmptyState.standard(
          text: 'Nenhum match ainda\nImplementar funcionalidade de matches',
        ),
      ),
    );
  }
}
