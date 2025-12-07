import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/app/services/localization_service.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/home/presentation/viewmodels/people_ranking_viewmodel.dart';
import 'package:partiu/features/home/presentation/viewmodels/ranking_viewmodel.dart';
import 'package:partiu/features/home/presentation/widgets/people_ranking_card.dart';
import 'package:partiu/features/home/presentation/widgets/people_ranking_card_shimmer.dart';
import 'package:partiu/features/home/presentation/widgets/place_card/place_card.dart';
import 'package:partiu/features/home/presentation/widgets/place_card/place_card_controller.dart';
import 'package:partiu/features/notifications/widgets/notification_horizontal_filters.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';
import 'package:partiu/shared/widgets/glimpse_tab_app_bar.dart';
import 'package:partiu/shared/widgets/glimpse_tab_header.dart';

/// Tela de ranking (Tab 2)
/// 
/// Exibe ranking de locais por eventos hospedados
class RankingTab extends StatefulWidget {
  const RankingTab({super.key});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  late final RankingViewModel _locationsViewModel;
  late final PeopleRankingViewModel _peopleViewModel;
  int _selectedTabIndex = 0; // 0 = Pessoas, 1 = Lugares

  @override
  void initState() {
    super.initState();
    debugPrint('🎴 [RankingTab] initState');
    
    _locationsViewModel = RankingViewModel();
    _peopleViewModel = PeopleRankingViewModel();
    
    _locationsViewModel.addListener(_onViewModelChanged);
    _peopleViewModel.addListener(_onViewModelChanged);
    
    // Inicializar rankings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🎴 [RankingTab] Inicializando ViewModels...');
      _locationsViewModel.initialize();
      _peopleViewModel.initialize();
    });
  }

  @override
  void dispose() {
    _locationsViewModel.removeListener(_onViewModelChanged);
    _peopleViewModel.removeListener(_onViewModelChanged);
    _locationsViewModel.dispose();
    _peopleViewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

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
            
            // Tab Header
            GlimpseTabHeader.withTabs(
              title: '',
              onSearchTap: () {
                // TODO: Implementar busca
              },
              tabLabels: const ['Pessoas', 'Lugares'],
              selectedTabIndex: _selectedTabIndex,
              onTabTap: (index) {
                debugPrint('🔄 [RankingTab] Mudando para tab: ${index == 0 ? "Pessoas" : "Lugares"}');
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
            
            const SizedBox(height: 0),
            
            // Conteúdo
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Selecionar ViewModel baseado na tab
    final isLoadingPeople = _selectedTabIndex == 0 && _peopleViewModel.isLoading;
    final isLoadingLocations = _selectedTabIndex == 1 && _locationsViewModel.isLoading;
    
    // Loading state com shimmer
    if (isLoadingPeople) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Espaço para o filtro (vazio durante loading)
          const SizedBox(height: 64),
          
          // Lista de shimmer cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) => const PeopleRankingCardShimmer(),
            ),
          ),
        ],
      );
    }
    
    if (isLoadingLocations) {
      return const Center(
        child: CupertinoActivityIndicator(radius: 16),
      );
    }

    // Error state
    final error = _selectedTabIndex == 0 
        ? _peopleViewModel.error 
        : _locationsViewModel.error;
    
    if (error != null) {
      return Center(
        child: GlimpseEmptyState.standard(
          text: error,
        ),
      );
    }

    // Mostrar tab baseado na seleção
    return _selectedTabIndex == 0 
        ? _buildPeopleRankingList() 
        : _buildLocationRankingList();
  }

  Widget _buildPeopleRankingList() {
    debugPrint('👥 [RankingTab] _buildPeopleRankingList');
    
    final rankings = _peopleViewModel.peopleRankings;
    final cities = _peopleViewModel.availableCities;
    
    debugPrint('   - rankings.length: ${rankings.length}');
    debugPrint('   - cities.length: ${cities.length}');
    debugPrint('   - isLoading: ${_peopleViewModel.isLoading}');
    debugPrint('   - error: ${_peopleViewModel.error}');
    
    if (rankings.isEmpty) {
      debugPrint('   ⚠️ Rankings vazio, mostrando empty state');
      return Center(
        child: GlimpseEmptyState.standard(
          text: 'Nenhuma pessoa no ranking ainda',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtro de cidade
        if (cities.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildCityFilter(cities),
          const SizedBox(height: 12),
        ],
        
        // Lista de pessoas
        Expanded(
          child: RefreshIndicator(
            onRefresh: _peopleViewModel.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: rankings.length,
              itemBuilder: (context, index) {
                final ranking = rankings[index];
                final position = index + 1;

                return PeopleRankingCard(
                  ranking: ranking,
                  position: position,
                  badgesCount: ranking.badgesCount,
                  criteriaRatings: ranking.criteriaRatings,
                  totalComments: ranking.totalComments,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityFilter(List<String> cities) {
    final selectedCity = _peopleViewModel.selectedCity;
    
    // Criar lista com "Todas" + cidades
    final items = ['Todas', ...cities];
    
    // Index selecionado (0 = Todas, 1+ = cidades)
    final selectedIndex = selectedCity == null 
        ? 0 
        : cities.indexOf(selectedCity) + 1;
    
    return NotificationHorizontalFilters(
      items: items,
      selectedIndex: selectedIndex,
      onSelected: (index) {
        if (index == 0) {
          _peopleViewModel.selectCity(null);
        } else {
          _peopleViewModel.selectCity(cities[index - 1]);
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildLocationRankingList() {
    final rankings = _locationsViewModel.locationRankings;
    
    if (rankings.isEmpty) {
      return Center(
        child: GlimpseEmptyState.standard(
          text: 'Nenhum local no ranking ainda',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _locationsViewModel.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rankings.length,
        itemBuilder: (context, index) {
          final ranking = rankings[index];
          final position = index + 1;

          // Criar controller com dados do ranking
          final controller = PlaceCardController(
            eventId: 'ranking_${ranking.placeId}',
            preloadedData: {
              'locationName': ranking.locationName,
              'formattedAddress': ranking.formattedAddress,
              'placeId': ranking.placeId,
              'photoReferences': ranking.photoReferences,
              'visitors': ranking.visitors,
              'totalVisitorsCount': ranking.totalVisitors,
            },
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GlimpseColors.borderColorLight,
                width: 1,
              ),
            ),
            child: PlaceCard(
              controller: controller,
              customTagWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GlimpseColors.primaryLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${ranking.totalEventsHosted} eventos',
                  style: GoogleFonts.getFont(
                    FONT_PLUS_JAKARTA_SANS,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: GlimpseColors.primaryDarker,
                  ),
                ),
              ),
              onTap: () {
                debugPrint('🏆 Local clicado: ${ranking.placeId}');
              },
            ),
          );
        },
      ),
    );
  }
}
