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
import 'package:partiu/features/home/presentation/state/people_ranking_state.dart';
import 'package:partiu/features/home/presentation/state/location_ranking_state.dart';
import 'package:partiu/features/notifications/widgets/notification_horizontal_filters.dart';
import 'package:partiu/features/notifications/widgets/notification_filter_shimmer.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';
import 'package:partiu/shared/widgets/glimpse_tab_app_bar.dart';
import 'package:partiu/shared/widgets/glimpse_tab_header.dart';
import 'package:partiu/shared/widgets/outline_horizontal_filter.dart';
import 'package:partiu/shared/widgets/infinite_list_view.dart';

/// Tela de ranking (Tab 2)
/// 
/// Exibe ranking de locais por eventos hospedados
class RankingTab extends StatefulWidget {
  const RankingTab({
    super.key,
    required this.peopleRankingViewModel,
    required this.locationsRankingViewModel,
  });
  
  final PeopleRankingViewModel peopleRankingViewModel;
  final RankingViewModel locationsRankingViewModel;

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  late final RankingViewModel _locationsViewModel;
  late final PeopleRankingViewModel _peopleViewModel;
  late final PeopleRankingState _peopleState;
  late final LocationRankingState _locationState;
  int _selectedTabIndex = 0; // 0 = Pessoas, 1 = Lugares

  @override
  void initState() {
    super.initState();
    debugPrint('🎴 [RankingTab] initState');
    
    // Usar o ViewModel pré-carregado do AppInitializer
    _locationsViewModel = widget.locationsRankingViewModel;
    _peopleViewModel = widget.peopleRankingViewModel;
    
    // Criar state holders com listas master
    _peopleState = PeopleRankingState(_peopleViewModel.peopleRankings);
    _locationState = LocationRankingState(_locationsViewModel.locationRankings);
    
    _locationsViewModel.addListener(_onLocationsViewModelChanged);
    _peopleViewModel.addListener(_onPeopleViewModelChanged);
    _peopleState.addListener(_onPeopleStateChanged);
    _locationState.addListener(_onLocationStateChanged);
    
    // Não precisa inicializar nada - tudo já foi pré-carregado no AppInitializer
    debugPrint('🎴 [RankingTab] ViewModels pré-carregados:');
    debugPrint('   - People: ${_peopleViewModel.peopleRankings.length}');
    debugPrint('   - Locations: ${_locationsViewModel.locationRankings.length}');
  }

  @override
  void dispose() {
    _locationsViewModel.removeListener(_onLocationsViewModelChanged);
    _peopleViewModel.removeListener(_onPeopleViewModelChanged);
    _peopleState.removeListener(_onPeopleStateChanged);
    _locationState.removeListener(_onLocationStateChanged);
    _peopleState.dispose();
    _locationState.dispose();
    // Não fazer dispose dos ViewModels pois eles são compartilhados
    super.dispose();
  }

  void _onLocationsViewModelChanged() {
    // Atualizar master list no state quando ViewModel recarregar
    _locationState.updateMaster(_locationsViewModel.locationRankings);
    if (mounted) {
      setState(() {});
    }
  }

  void _onPeopleViewModelChanged() {
    // Atualizar master list no state quando ViewModel recarregar
    _peopleState.updateMaster(_peopleViewModel.peopleRankings);
    if (mounted) {
      setState(() {});
    }
  }

  void _onPeopleStateChanged() {
    // State mudou (filtro aplicado) - apenas rebuild
    if (mounted) {
      setState(() {});
    }
  }

  void _onLocationStateChanged() {
    // State mudou (filtro aplicado) - apenas rebuild
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
          // Container fixo para o shimmer do filtro
          const SizedBox(
            height: 56, // Altura fixa para manter espaço consistente
            child: NotificationFilterShimmer(),
          ),
          
          const SizedBox(height: 12),
          
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
    
    final master = _peopleState.master;
    final visibleIds = _peopleState.visibleIds;
    final states = _peopleState.availableStates;
    final cities = _peopleState.availableCities;
    
    debugPrint('   - master.length: ${master.length}');
    debugPrint('   - visibleIds.length: ${visibleIds.length}');
    debugPrint('   - states.length: ${states.length}');
    debugPrint('   - cities.length: ${cities.length}');
    
    if (master.isEmpty) {
      debugPrint('   ⚠️ Master vazio, mostrando empty state');
      return Center(
        child: GlimpseEmptyState.standard(
          text: 'Nenhuma pessoa no ranking ainda',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Container para ambos os filtros (altura consistente)
        Column(
          children: [
            // Filtro de Estado (padrão)
            if (states.isNotEmpty)
              SizedBox(
                height: 48,
                child: _buildStateFilter(states),
              ),
            
            if (states.isNotEmpty && cities.isNotEmpty)
              const SizedBox(height: 8),
            
            // Filtro de Cidade (outline)
            if (cities.isNotEmpty)
              SizedBox(
                height: 38,
                child: _buildCityFilter(cities),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Lista de pessoas - 🚀 USANDO InfiniteListView com paginação
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _peopleViewModel.refresh();
            },
            child: InfiniteListView(
              controller: ScrollController(),
              itemCount: _peopleState.displayedRankings.length,
              itemBuilder: (context, index) {
                final ranking = _peopleState.displayedRankings[index];
                
                // Calcular posição real no ranking (considerando filtros)
                final allFiltered = _peopleState.filteredItems;
                final position = allFiltered.indexOf(ranking) + 1;

                return PeopleRankingCard(
                  key: ValueKey(ranking.userId),
                  ranking: ranking,
                  position: position,
                  badgesCount: ranking.badgesCount,
                  criteriaRatings: ranking.criteriaRatings,
                  totalComments: ranking.totalComments,
                );
              },
              onLoadMore: _peopleState.loadMore,
              isLoadingMore: false, // Dados já em memória
              exhausted: !_peopleState.hasMore,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateFilter(List<String> states) {
    final selectedState = _peopleState.filter.state;
    
    // Criar lista com "Todos" + estados
    final items = ['Todos', ...states];
    
    // Index selecionado (0 = Todos, 1+ = estados)
    final selectedIndex = selectedState == null 
        ? 0 
        : states.indexOf(selectedState) + 1;
    
    return NotificationHorizontalFilters(
      items: items,
      selectedIndex: selectedIndex,
      onSelected: (index) {
        if (index == 0) {
          _peopleState.setStateFilter(null);
        } else {
          _peopleState.setStateFilter(states[index - 1]);
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildCityFilter(List<String> cities) {
    final selectedCity = _peopleState.filter.city;
    
    // Criar lista com "Todas" + cidades
    final values = ['Todas', ...cities];
    
    // Valor selecionado (null = Todas, string = cidade específica)
    final selected = selectedCity ?? 'Todas';
    
    return OutlineHorizontalFilter(
      values: values,
      selected: selected,
      onSelected: (value) {
        if (value == null || value == 'Todas') {
          _peopleState.setCityFilter(null);
        } else {
          _peopleState.setCityFilter(value);
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildLocationRankingList() {
    debugPrint('🏢 [RankingTab] _buildLocationRankingList');
    
    final master = _locationState.master;
    final visibleIds = _locationState.visibleIds;
    final states = _locationState.availableStates;
    final cities = _locationState.availableCities;
    
    debugPrint('   - master.length: ${master.length}');
    debugPrint('   - visibleIds.length: ${visibleIds.length}');
    debugPrint('   - states.length: ${states.length}');
    debugPrint('   - cities.length: ${cities.length}');
    
    if (master.isEmpty) {
      debugPrint('   ⚠️ Master vazio, mostrando empty state');
      return Center(
        child: GlimpseEmptyState.standard(
          text: 'Nenhum local no ranking ainda',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Container para ambos os filtros (altura consistente)
        Column(
          children: [
            // Filtro de Estado (padrão)
            if (states.isNotEmpty)
              SizedBox(
                height: 48,
                child: _buildLocationStateFilter(states),
              ),
            
            if (states.isNotEmpty && cities.isNotEmpty)
              const SizedBox(height: 8),
            
            // Filtro de Cidade (outline)
            if (cities.isNotEmpty)
              SizedBox(
                height: 38,
                child: _buildLocationCityFilter(cities),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Lista de locais - 🚀 USANDO InfiniteListView com paginação
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _locationsViewModel.refresh();
            },
            child: InfiniteListView(
              controller: ScrollController(),
              itemCount: _locationState.displayedRankings.length,
              itemBuilder: (context, index) {
                final ranking = _locationState.displayedRankings[index];
                
                // Calcular posição real no ranking (considerando filtros)
                final allFiltered = _locationState.filteredItems;
                final position = allFiltered.indexOf(ranking) + 1;

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
                  key: ValueKey(ranking.placeId),
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
              onLoadMore: _locationState.loadMore,
              isLoadingMore: false, // Dados já em memória
              exhausted: !_locationState.hasMore,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStateFilter(List<String> states) {
    final selectedState = _locationState.filter.state;
    
    // Criar lista com "Todos" + estados
    final items = ['Todos', ...states];
    
    // Index selecionado (0 = Todos, 1+ = estados)
    final selectedIndex = selectedState == null 
        ? 0 
        : states.indexOf(selectedState) + 1;
    
    return NotificationHorizontalFilters(
      items: items,
      selectedIndex: selectedIndex,
      onSelected: (index) {
        if (index == 0) {
          _locationState.setStateFilter(null);
        } else {
          _locationState.setStateFilter(states[index - 1]);
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildLocationCityFilter(List<String> cities) {
    final selectedCity = _locationState.filter.city;
    
    // Criar lista com "Todas" + cidades
    final values = ['Todas', ...cities];
    
    // Valor selecionado (null = Todas, string = cidade específica)
    final selected = selectedCity ?? 'Todas';
    
    return OutlineHorizontalFilter(
      values: values,
      selected: selected,
      onSelected: (value) {
        if (value == null || value == 'Todas') {
          _locationState.setCityFilter(null);
        } else {
          _locationState.setCityFilter(value);
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

