import 'dart:async';

import 'package:dating_app/constants/constants.dart';
import 'package:dating_app/constants/glimpse_variables.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/screens/discover_vendor/widgets/vendor_horizontal_filter.dart';
import 'package:dating_app/screens/ranking/models/ranking_entry.dart';
import 'package:dating_app/screens/ranking/viewmodels/local_ranking_viewmodel.dart';
import 'package:dating_app/screens/ranking/viewmodels/global_ranking_viewmodel.dart';
import 'package:dating_app/screens/ranking/widgets/ranking_card.dart';
import 'package:dating_app/screens/ranking/widgets/ranking_user_card.dart';
import 'package:dating_app/screens/ranking/widgets/winner_podium_card.dart';
import 'package:dating_app/widgets/glimpse_empty_state.dart';
import 'package:dating_app/widgets/glimpse_tab_header.dart';
import 'package:dating_app/widgets/platform_pull_to_refresh.dart';
import 'package:dating_app/widgets/skeletons/ranking_card_skeleton.dart';
import 'package:dating_app/widgets/sliding_search.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class RankingTab extends StatefulWidget {
  const RankingTab({super.key});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _categories = ['All', ...interestListDisplay];

  final ScrollController _localController = ScrollController();
  final ScrollController _globalController = ScrollController();

  late final LocalRankingViewModel _localVM;
  late final GlobalRankingViewModel _globalVM;

  int _currentTab = 0;

  bool _isSearching = false;
  String _searchQuery = '';
  List<RankingEntry> _searchResults = [];
  final SlidingSearchController _searchController = SlidingSearchController();

  @override
  void initState() {
    super.initState();

    _localVM = LocalRankingViewModel();
    _globalVM = GlobalRankingViewModel();

    _localController.addListener(() => _onScroll(_localVM, _localController));
    _globalController.addListener(() => _onScroll(_globalVM, _globalController));

    _initLocationAndData();

    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.query;
      });
    });
  }

  Future<void> _initLocationAndData() async {
    Position? pos;

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        pos = await Geolocator.getCurrentPosition();
      }
    } catch (_) {}

    if (!mounted) return;

    await _localVM.initialize(pos);
    await _globalVM.initialize();
  }

  @override
  void dispose() {
    _localController.dispose();
    _globalController.dispose();
    _localVM.dispose();
    _globalVM.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Scroll infinito unificado
  void _onScroll(dynamic vm, ScrollController c) {
    if (_isSearching) return;
    if (c.position.pixels >= c.position.maxScrollExtent - 200) {
      vm.loadRankings();
    }
  }

  // SEARCH
  void _onSearchTap() {
    final i18n = AppLocalizations.of(context);

    setState(() {
      _isSearching = true;
      _searchQuery = '';
      _searchResults = [];
    });

    SlidingSearch.show(
      context,
      controller: _searchController,
      placeholder: i18n.translate('search_profiles'),
      hintText: i18n.translate('search_hint_profile'),
      searchUsers: true,
      limitPerSource: 20,
      onResults: (results) {
        if (!mounted) return;

        setState(() {
          _searchResults = results.users
              .map(
                (u) => RankingEntry(
                  userId: u['id'],
                  position: 0,
                  overallRating: 0,
                  totalReviews: 0,
                  fullName: u[USER_FULLNAME] ?? '',
                  photoUrl: u[USER_PROFILE_PHOTO],
                  jobTitle: 'Vendor',
                  locality: u[USER_LOCALITY],
                  state: u[USER_STATE],
                ),
              )
              .toList();
        });
      },
      onClose: () {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _searchQuery = '';
          _searchResults = [];
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final i18n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isLocal = _currentTab == 0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlimpseTabHeader.withTabs(
              title: i18n.translate('ranking'),
              isDarkMode: isDark,
              tabLabels: [
                i18n.translate('ranking_local'),
                i18n.translate('ranking_global'),
              ],
              selectedTabIndex: _currentTab,
              onTabTap: (i) => setState(() => _currentTab = i),
              onSearchTap: _onSearchTap,
            ),

            const SizedBox(height: 8),

            // FILTRO (esconde só durante busca)
            if (!_isSearching || _searchQuery.isEmpty)
              _buildCategoryFilter(isLocal),

            Expanded(
              child: (_isSearching && _searchQuery.isNotEmpty)
                  ? _buildSearchResults(i18n)
                  : isLocal
                      ? _buildRankingList(_localVM, _localController, i18n)
                      : _buildRankingList(_globalVM, _globalController, i18n),
            ),
          ],
        ),
      ),
    );
  }

  // FILTRO DE CATEGORIA
  Widget _buildCategoryFilter(bool isLocal) {
    if (isLocal) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AnimatedBuilder(
          animation: _localVM,
          builder: (_, __) {
            return VendorHorizontalFilter(
              categories: _categories,
              selectedIndex: _categories.indexOf(_localVM.selectedCategory),
              onCategorySelected: (i) => _localVM.changeCategory(_categories[i]),
            );
          },
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AnimatedBuilder(
          animation: _globalVM,
          builder: (_, __) {
            return VendorHorizontalFilter(
              categories: _categories,
              selectedIndex: _categories.indexOf(_globalVM.selectedCategory),
              onCategorySelected: (i) => _globalVM.changeCategory(_categories[i]),
            );
          },
        ),
      );
    }
  }

  // RESULTADOS DE BUSCA
  Widget _buildSearchResults(AppLocalizations i18n) {
    if (_searchResults.isEmpty) {
      return Center(
        child: GlimpseEmptyState(
          text: i18n.translate('no_results_found'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (_, i) => RankingCard(entry: _searchResults[i]),
    );
  }

  // LISTA LOCAL + GLOBAL (UNIFICADO)
  Widget _buildRankingList(
      dynamic vm, ScrollController controller, AppLocalizations i18n) {
    return AnimatedBuilder(
      animation: vm,
      builder: (_, __) {
        final items = _buildItems(vm);

        // Loading inicial: skeletons em vez de spinner
        if (vm.isLoading && vm.rankings.isEmpty) {
          return ListView.builder(
            key: PageStorageKey(
              'ranking_skeleton_${_currentTab == 0 ? 'local' : 'global'}',
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: 8,
            itemBuilder: (_, __) => const RankingCardSkeleton(),
          );
        }

        // Empty state (sem pull-to-refresh quando não há dados)
        if (items.isEmpty) {
          return Center(
            child: GlimpseEmptyState(
              text: vm is LocalRankingViewModel && !vm.hasPosition
                  ? i18n.translate('gps_disabled')
                  : i18n.translate('no_vendors_found'),
            ),
          );
        }

        // Lista com pull-to-refresh estilo plataforma + load more via scroll
        return PlatformPullToRefresh(
          key: PageStorageKey(
              'ranking_${_currentTab == 0 ? 'local' : 'global'}'),
          controller: controller,
          padding: EdgeInsets.zero,
          itemCount: items.length + (vm.isLoadingMore ? 1 : 0),
          onRefresh: () async {
            await vm.loadRankings(refresh: true);
          },
          cacheInvalidationPatterns: const [
            'ranking_local_*',
            'ranking_global_*',
            'review_stats_*',
            'user_*',
          ],
          itemBuilder: (context, index) {
            if (index == items.length) {
              // Skeleton de "carregando mais"
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: RankingCardSkeleton(),
              );
            }
            return items[index];
          },
        );
      },
    );
  }

  // MONTA LISTA FINAL
  List<Widget> _buildItems(dynamic vm) {
    final List<Widget> out = [];

    if (vm.currentUserRanking != null &&
        vm.currentUserRanking!.position > 10) {
      out.add(
        Column(
          children: [
            const SizedBox(height: 16),
            RankingUserCard(entry: vm.currentUserRanking!),
            const Divider(height: 32),
          ],
        ),
      );
    } else {
      // Se não tem user card, adiciona padding no início
      out.add(const SizedBox(height: 16));
    }

    for (int i = 0; i < vm.rankings.length && i < 3; i++) {
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: WinnerPodiumCard(entry: vm.rankings[i]),
        ),
      );
    }

    for (int i = 3; i < vm.rankings.length; i++) {
      out.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: RankingCard(
            entry: vm.rankings[i],
            margin: const EdgeInsets.only(bottom: 8),
          ),
        ),
      );
    }

    return out;
  }
}
