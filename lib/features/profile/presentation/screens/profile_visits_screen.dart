import 'package:flutter/material.dart';
import 'package:partiu/shared/widgets/glimpse_app_bar.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';
import 'package:partiu/features/profile/data/services/profile_visits_service.dart';
import 'package:partiu/features/home/presentation/widgets/user_card.dart';
import 'package:partiu/features/home/presentation/widgets/user_card_shimmer.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/models/user.dart';

/// Tela para exibir as visitas ao perfil do usuário
/// 
/// Features:
/// - Stream em tempo real de visitas
/// - Usa UserCard para exibir visitantes
/// - Empty state quando sem visitas
/// - Tempo relativo da visita
/// - Otimizado: carrega dados de todos os visitantes em lote
class ProfileVisitsScreen extends StatelessWidget {
  const ProfileVisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AppState.currentUserId ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlimpseAppBar(
        title: 'Visitas ao Perfil',
      ),
      body: userId.isEmpty
          ? Center(
              child: GlimpseEmptyState.standard(
                text: 'Usuário não autenticado',
              ),
            )
          : StreamBuilder<List<User>>(
              stream: ProfileVisitsService.instance.watchVisitsWithUserData(userId),
              builder: (context, snapshot) {
                // Loading inicial
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
                      text: 'Erro ao carregar visitas',
                    ),
                  );
                }

                final visits = snapshot.data ?? [];

                // Empty
                if (visits.isEmpty) {
                  return Center(
                    child: GlimpseEmptyState.standard(
                      text: 'Nenhuma visita ainda',
                    ),
                  );
                }

                // Success - Lista de visitantes usando UserCard com dados completos
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: visits.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final visitor = visits[index];
                    return UserCard(
                      key: ValueKey(visitor.userId),
                      user: visitor, // Passa objeto User completo com distância e interesses
                      userId: visitor.userId,
                    );
                  },
                );
              },
            ),
    );
  }
}
