import 'package:flutter/material.dart';
import 'package:partiu/app/services/localization_service.dart';
import 'package:partiu/features/home/data/models/pending_application_model.dart';
import 'package:partiu/features/home/data/repositories/pending_applications_repository.dart';
import 'package:partiu/features/home/presentation/widgets/approve_card.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';
import 'package:partiu/shared/widgets/glimpse_tab_app_bar.dart';

/// Tela de ações (Tab 1)
/// 
/// Exibe aplicações pendentes de aprovação para eventos criados pelo usuário
class ActionsTab extends StatefulWidget {
  const ActionsTab({super.key});

  @override
  State<ActionsTab> createState() => _ActionsTabState();
}

class _ActionsTabState extends State<ActionsTab> {
  final PendingApplicationsRepository _repo = PendingApplicationsRepository();

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 ActionsTab: initState');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 ActionsTab: build');
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            GlimpseTabAppBar(
              title: LocalizationService.of(context).translate('actions') ?? 'Ações',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<PendingApplicationModel>>(
                stream: _repo.getPendingApplicationsStream(),
                builder: (context, snapshot) {
                  debugPrint('📡 ActionsTab StreamBuilder:');
                  debugPrint('   - connectionState: ${snapshot.connectionState}');
                  debugPrint('   - hasData: ${snapshot.hasData}');
                  debugPrint('   - hasError: ${snapshot.hasError}');
                  
                  if (snapshot.hasError) {
                    debugPrint('   ❌ Error: ${snapshot.error}');
                  }
                  
                  if (snapshot.hasData) {
                    debugPrint('   ✅ Data length: ${snapshot.data?.length ?? 0}');
                    for (var i = 0; i < (snapshot.data?.length ?? 0); i++) {
                      final app = snapshot.data![i];
                      debugPrint('      [$i] ${app.userFullName} -> ${app.activityText}');
                      debugPrint('          applicationId: ${app.applicationId}');
                      debugPrint('          eventId: ${app.eventId}');
                      debugPrint('          userId: ${app.userId}');
                    }
                  }
                  
                  // Loading inicial
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    debugPrint('   ⏳ Aguardando dados iniciais...');
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Error
                  if (snapshot.hasError) {
                    return Center(
                      child: GlimpseEmptyState.standard(
                        text: 'Erro ao carregar solicitações',
                      ),
                    );
                  }

                  // Empty (verifica se não tem dados OU se a lista está vazia)
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    debugPrint('   📭 Nenhuma aplicação pendente');
                    return Center(
                      child: GlimpseEmptyState.standard(
                        text: 'Nenhuma solicitação pendente',
                      ),
                    );
                  }

                  // List
                  final applications = snapshot.data!;
                  debugPrint('   📋 Renderizando ${applications.length} cards');
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: applications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      debugPrint('   🎴 Criando card $index: ${applications[index].applicationId}');
                      return ApproveCard(
                        key: ValueKey(applications[index].applicationId),
                        application: applications[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
