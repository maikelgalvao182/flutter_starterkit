import 'package:flutter/material.dart';
import 'package:partiu/shared/widgets/glimpse_app_bar.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';
import 'package:partiu/shared/widgets/infinite_list_view.dart';
import 'package:partiu/features/profile/presentation/controllers/profile_visits_controller.dart';
import 'package:partiu/features/home/presentation/widgets/user_card.dart';
import 'package:partiu/features/home/presentation/widgets/user_card_shimmer.dart';
import 'package:partiu/common/state/app_state.dart';

/// Tela para exibir as visitas ao perfil do usuário
/// 
/// Features:
/// - 🔥 OTIMIZADO: Lista local + Stream de eventos
/// - 🚀 PAGINAÇÃO: Usa InfiniteListView para scroll infinito
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
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    final userId = AppState.currentUserId ?? '';
    ProfileVisitsController.instance.watchUser(userId);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
              separatorBuilder: (context, index) => const SizedBox(height: 16),
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

          // Success - Lista de visitantes com paginação
          // 🚀 OTIMIZAÇÃO: InfiniteListView carrega 20 por vez
          final displayedVisitors = controller.displayedVisitors;

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: InfiniteListView(
              controller: _scrollController,
              itemCount: displayedVisitors.length,
              itemBuilder: (context, index) {
                final visitor = displayedVisitors[index];
                return UserCard(
                  key: ValueKey(visitor.userId),
                  user: visitor,
                  userId: visitor.userId,
                  overallRating: visitor.overallRating,
                  index: index,
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              onLoadMore: controller.loadMore,
              isLoadingMore: controller.isLoadingMore,
              exhausted: !controller.hasMore,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
          );
        },
      ),
    );
  }
}
