import 'package:flutter/material.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';
import 'package:partiu/shared/widgets/glimpse_tab_app_bar.dart';
import 'package:partiu/app/services/localization_service.dart';

/// Tela de ranking (Tab 2)
/// TODO: Implementar funcionalidade de ranking
class RankingTab extends StatelessWidget {
  const RankingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            GlimpseTabAppBar(
              title: LocalizationService.of(context).translate('ranking') ?? 'Ranking',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: GlimpseEmptyState.standard(
                  text: 'Ranking ainda não disponível\nImplementar funcionalidade de ranking',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
