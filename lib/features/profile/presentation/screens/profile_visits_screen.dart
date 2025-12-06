import 'package:flutter/material.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_app_bar.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';
import 'package:partiu/features/profile/data/services/profile_visits_service.dart';
import 'package:partiu/features/home/presentation/widgets/user_card.dart';
import 'package:partiu/features/home/presentation/widgets/user_card_shimmer.dart';
import 'package:partiu/common/state/app_state.dart';

/// Tela para exibir as visitas ao perfil do usuário
/// 
/// Features:
/// - Stream em tempo real de visitas
/// - Usa UserCard para exibir visitantes
/// - Empty state quando sem visitas
/// - Tempo relativo da visita
class ProfileVisitsScreen extends StatelessWidget {
  const ProfileVisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final userId = AppState.currentUserId ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlimpseAppBar(
        title: i18n.translate('profile_visits') ?? 'Visitas ao Perfil',
      ),
      body: userId.isEmpty
          ? Center(
              child: GlimpseEmptyState.standard(
                text: i18n.translate('user_not_authenticated') ?? 'Usuário não autenticado',
              ),
            )
          : StreamBuilder<List<ProfileVisit>>(
              stream: ProfileVisitsService.instance.watchVisits(userId),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: 5,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => const UserCardShimmer(),
                  );
                }

                // Error
                if (snapshot.hasError) {
                  return Center(
                    child: GlimpseEmptyState.standard(
                      text: i18n.translate('error_loading_visits') ?? 'Erro ao carregar visitas',
                    ),
                  );
                }

                final visits = snapshot.data ?? [];

                // Empty
                if (visits.isEmpty) {
                  return Center(
                    child: GlimpseEmptyState.standard(
                      text: i18n.translate('no_visits_yet') ?? 'Nenhuma visita ainda',
                    ),
                  );
                }

                // Success - Lista de visitantes usando UserCard
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: visits.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final visit = visits[index];
                    return UserCard(
                      key: ValueKey(visit.visitorId),
                      userId: visit.visitorId,
                      trailingWidget: _buildVisitTime(visit.visitedAt),
                    );
                  },
                );
              },
            ),
    );
  }

  /// Widget para exibir tempo relativo da visita
  Widget _buildVisitTime(DateTime visitedAt) {
    final now = DateTime.now();
    final difference = now.difference(visitedAt);

    String timeText;
    if (difference.inMinutes < 1) {
      timeText = 'Agora';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      timeText = '${minutes}min';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      timeText = '${hours}h';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      timeText = '${days}d';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      timeText = '${weeks}sem';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      timeText = '${months}m';
    } else {
      final years = (difference.inDays / 365).floor();
      timeText = '${years}a';
    }

    return SizedBox(
      width: 50,
      child: Text(
        timeText,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6F6E6E),
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}
