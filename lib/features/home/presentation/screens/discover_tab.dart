import 'package:flutter/material.dart';
import 'package:partiu/features/home/create_flow/create_flow_coordinator.dart';
import 'package:partiu/features/home/presentation/screens/discover_screen.dart';
import 'package:partiu/features/home/presentation/screens/location_picker/location_picker_page_refactored.dart';
import 'package:partiu/features/home/presentation/widgets/category_drawer.dart';
import 'package:partiu/features/home/presentation/widgets/create_button.dart';
import 'package:partiu/features/home/presentation/widgets/create_drawer.dart';
import 'package:partiu/features/home/presentation/widgets/list_button.dart';
import 'package:partiu/features/home/presentation/widgets/list_drawer.dart';
import 'package:partiu/features/home/presentation/widgets/list_drawer/list_drawer_controller.dart';
import 'package:partiu/features/home/presentation/widgets/navigate_to_user_button.dart';
import 'package:partiu/features/home/presentation/widgets/people_button.dart';
import 'package:partiu/features/home/presentation/screens/find_people_screen.dart';
import 'package:partiu/features/home/presentation/viewmodels/map_viewmodel.dart';
import 'package:partiu/features/home/presentation/screens/find_people/find_people_controller.dart';
import 'package:partiu/features/home/presentation/widgets/schedule_drawer.dart';
import 'package:provider/provider.dart';

/// Tela de descoberta (Tab 0)
/// Exibe mapa interativo com atividades próximas
class DiscoverTab extends StatefulWidget {
  const DiscoverTab({
    super.key,
    required this.mapViewModel,
  });

  final MapViewModel mapViewModel;

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final GlobalKey<DiscoverScreenState> _discoverKey = GlobalKey<DiscoverScreenState>();

  void _showCreateDrawer(BuildContext context) async {
    final coordinator = CreateFlowCoordinator(mapViewModel: widget.mapViewModel);
    
    // Loop para gerenciar navegação entre drawers
    while (true) {
      // Mostra CreateDrawer (nunca em editMode no fluxo de criação)
      final createResult = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => CreateDrawer(
          coordinator: coordinator,
          initialName: coordinator.draft.activityText,
          initialEmoji: coordinator.draft.emoji,
        ),
      );

      // Se fechou sem ação, sair do fluxo
      if (createResult == null) break;

      // Se pediu para abrir CategoryDrawer
      if (createResult['action'] == 'openCategory') {
        final categoryResult = await _showCategoryFlow(context, coordinator);
        
        // Se voltou do CategoryDrawer, continua o loop para reabrir CreateDrawer
        if (categoryResult != null && categoryResult['action'] == 'back') {
          continue;
        }
        
        // Se completou o fluxo ou fechou, sair
        break;
      }
      
      break;
    }
  }

  Future<Map<String, dynamic>?> _showCategoryFlow(BuildContext context, CreateFlowCoordinator coordinator) async {
    // Loop para gerenciar navegação entre CategoryDrawer, ScheduleDrawer e LocationPicker
    while (true) {
      final categoryResult = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => CategoryDrawer(
          coordinator: coordinator,
          initialCategory: coordinator.draft.category,
        ),
      );

      // Se voltou para CreateDrawer
      if (categoryResult != null && categoryResult['action'] == 'back') {
        return categoryResult;
      }

      // Se fechou sem resultado, sair
      if (categoryResult == null) return null;

      // Se pediu para abrir LocationPicker (veio do ScheduleDrawer)
      if (categoryResult['action'] == 'openLocationPicker') {
        final locationResult = await _showLocationPickerFlow(context, coordinator);
        
        // Se voltou do LocationPicker, continua o loop para reabrir CategoryDrawer/ScheduleDrawer
        if (locationResult != null && locationResult['action'] == 'back') {
          continue;
        }
        
        // Fluxo completado ou cancelado
        return locationResult;
      }
      
      return categoryResult;
    }
  }

  Future<Map<String, dynamic>?> _showLocationPickerFlow(BuildContext context, CreateFlowCoordinator coordinator) async {
    final locationResult = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPageRefactored(
          coordinator: coordinator,
        ),
        fullscreenDialog: true,
      ),
    );

    return locationResult;
  }

  void _showListDrawer(BuildContext context) {
    // Usa bottom sheet nativo
    ListDrawer.show(context);
  }

  void _centerOnUser() {
    _discoverKey.currentState?.centerOnUser();
  }

  void _showPeopleNearby() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FindPeopleScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mapa Apple Maps
        DiscoverScreen(
          key: _discoverKey,
          mapViewModel: widget.mapViewModel,
        ),
        
        // Botão "Perto de você" (canto superior direito)
        Positioned(
          top: 16,
          right: 16,
          child: PeopleButton(
            onPressed: _showPeopleNearby,
          ),
        ),
        
        // Botão de centralizar no usuário
        Positioned(
          right: 16,
          bottom: 96, // 24 (bottom do CreateButton) + 56 (tamanho do FAB) + 16 (espaçamento)
          child: NavigateToUserButton(
            onPressed: _centerOnUser,
          ),
        ),
        
        // Botão de lista de atividades (centro inferior)
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Center(
            child: ListButton(
              onPressed: () => _showListDrawer(context),
            ),
          ),
        ),
        
        // Botão flutuante para criar atividade
        Positioned(
          right: 16,
          bottom: 24,
          child: CreateButton(
            onPressed: () => _showCreateDrawer(context),
          ),
        ),
      ],
    );
  }
}
