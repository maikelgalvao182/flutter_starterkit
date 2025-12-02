import 'package:flutter/material.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';

/// Tela de ranking (Tab 2)
/// TODO: Implementar funcionalidade de ranking
class RankingTab extends StatelessWidget {
  const RankingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: GlimpseEmptyState.standard(
          text: 'Ranking ainda não disponível\nImplementar funcionalidade de ranking',
        ),
      ),
    );
  }
}
