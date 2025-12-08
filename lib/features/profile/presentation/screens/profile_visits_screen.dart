import 'package:flutter/material.dart';
import 'package:partiu/shared/widgets/glimpse_app_bar.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';
import 'package:partiu/features/profile/presentation/controllers/profile_visits_controller.dart';
import 'package:partiu/features/home/presentation/widgets/user_card.dart';
import 'package:partiu/features/home/presentation/widgets/user_card_shimmer.dart';
import 'package:partiu/common/state/app_state.dart';

/// Tela para exibir as visitas ao perfil do usuário
/// 
/// Features:
/// - 🔥 OTIMIZADO: Lista local + Stream de eventos
/// - Não reconstrói toda a lista a cada mudança
/// - Apenas cards afetados atualizam
/// - Scroll não reseta
/// - Performance muito superior
class ProfileVisitsScreen extends StatefulWidget {
  const ProfileVisitsScreen({super.key});

  @override
  State<ProfileVisitsScreen> createState() => _ProfileVisitsScreenState();
}

class _ProfileVisitsScreenState extends State<ProfileVisitsScreen> {
  @override
  void initState() {
    super.initState();
    final userId = AppState.currentUserId ?? '';
    ProfileVisitsController.instance.watchUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlimpseAppBar(
        title: 'Visitas ao Perfil',
      ),
      body: AnimatedBuilder(
        animation: ProfileVisitsController.instance,
        builder: (context, _) {
          final controller = ProfileVisitsController.instance;
          
          // Loading inicial
          if (controller.isLoading) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => const UserCardShimmer(),
            );
          }

          // Error
          if (controller.error != null) {
            return Center(
              child: GlimpseEmptyState.standard(
                text: controller.error!,
              ),
            );
          }

          // Empty
          if (controller.isEmpty) {
            return Center(
              child: GlimpseEmptyState.standard(
                text: 'Nenhuma visita ainda',
              ),
            );
          }

          // Success - Lista de visitantes
          final visitors = controller.visitors;

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: visitors.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final visitor = visitors[index];
                return UserCard(
                  key: ValueKey(visitor.userId),
                  user: visitor,
                  userId: visitor.userId,
                  overallRating: visitor.overallRating,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
