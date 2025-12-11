/// GUIA DE IMPLEMENTAÇÃO - InfiniteListView
/// 
/// Este guia mostra como usar o serviço global de paginação
/// nas principais telas do app Partiu.
///
/// 📦 ARQUITETURA:
/// ✅ InfiniteListView: Widget global (UI + comportamento)
/// ❌ Lógica de dados: Local no Controller/ViewModel de cada tela
///
/// ═══════════════════════════════════════════════════════════════════

/// ═══════════════════════════════════════════════════════════════════
/// 1️⃣ PROFILE VISITS SCREEN
/// ═══════════════════════════════════════════════════════════════════
/// 
/// BENEFÍCIO:
/// - Lista pode crescer muito (centenas de visitas)
/// - Carrega 20 por vez, mostra loading no fim
/// - Scroll preservado, sem rebuilds
/// 
/// ANTES:
/// ```dart
/// ListView.separated(
///   itemCount: visitors.length,
///   itemBuilder: (context, index) => UserCard(...),
/// )
/// ```
/// 
/// DEPOIS:
/// ```dart
/// // No ProfileVisitsController:
/// class ProfileVisitsController extends ChangeNotifier {
///   List<ProfileVisitor> visitors = [];
///   bool isLoadingMore = false;
///   bool exhausted = false;
///   DocumentSnapshot? _lastDoc;
///   
///   Future<void> loadMore() async {
///     if (isLoadingMore || exhausted) return;
///     
///     isLoadingMore = true;
///     notifyListeners();
///     
///     try {
///       final query = FirebaseFirestore.instance
///           .collection('users')
///           .doc(userId)
///           .collection('profile_visits')
///           .orderBy('visitedAt', descending: true)
///           .limit(20);
///       
///       final snapshot = _lastDoc != null 
///           ? await query.startAfterDocument(_lastDoc!).get()
///           : await query.get();
///       
///       if (snapshot.docs.isEmpty) {
///         exhausted = true;
///       } else {
///         _lastDoc = snapshot.docs.last;
///         visitors.addAll(
///           snapshot.docs.map((doc) => ProfileVisitor.fromDoc(doc))
///         );
///       }
///     } finally {
///       isLoadingMore = false;
///       notifyListeners();
///     }
///   }
/// }
/// 
/// // Na UI:
/// InfiniteListView(
///   controller: _scrollController,
///   itemCount: controller.visitors.length,
///   itemBuilder: (context, index) {
///     final visitor = controller.visitors[index];
///     return UserCard(
///       key: ValueKey(visitor.userId),
///       user: visitor,
///       userId: visitor.userId,
///       overallRating: visitor.overallRating,
///     );
///   },
///   separatorBuilder: (_, __) => const SizedBox(height: 16),
///   onLoadMore: controller.loadMore,
///   isLoadingMore: controller.isLoadingMore,
///   exhausted: controller.exhausted,
///   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
/// )
/// ```

/// ═══════════════════════════════════════════════════════════════════
/// 2️⃣ NOTIFICATIONS SCREEN (SimplifiedNotificationScreen)
/// ═══════════════════════════════════════════════════════════════════
/// 
/// BENEFÍCIO:
/// - Já tem paginação manual com loadMore()
/// - InfiniteListView torna automático
/// - Reduz código, melhora UX
/// 
/// MUDANÇA:
/// ```dart
/// // No SimplifiedNotificationController, adicionar:
/// bool isLoadingMore = false;
/// bool exhausted = false;
/// 
/// Future<void> loadMore() async {
///   final filterKey = selectedFilterKey;
///   
///   if (isLoadingMore || exhausted) return;
///   if (!hasMoreForFilter(filterKey)) {
///     exhausted = true;
///     return;
///   }
///   
///   isLoadingMore = true;
///   notifyListeners();
///   
///   try {
///     await loadMoreForFilter(filterKey);
///   } finally {
///     isLoadingMore = false;
///     notifyListeners();
///   }
/// }
/// 
/// // Na _NotificationFilterPage widget, substituir CustomScrollView por:
/// InfiniteListView(
///   controller: _scrollController,
///   itemCount: notifications.length,
///   itemBuilder: (context, index) {
///     return NotificationItemWidget(
///       key: ValueKey(notifications[index].id),
///       notification: notifications[index],
///       isVipEffective: isVipEffective,
///     );
///   },
///   onLoadMore: () => widget.controller.loadMore(),
///   isLoadingMore: widget.controller.isLoadingMore,
///   exhausted: !hasMore,
///   padding: const EdgeInsets.symmetric(horizontal: 16),
/// )
/// ```

/// ═══════════════════════════════════════════════════════════════════
/// 3️⃣ FIND PEOPLE SCREEN
/// ═══════════════════════════════════════════════════════════════════
/// 
/// BENEFÍCIO:
/// - Se houver muitos usuários (50+), pode paginar
/// - Mostra 20 inicialmente, carrega mais ao scrollar
/// - Reduz uso de memória e CPU
/// 
/// IMPLEMENTAÇÃO (OPCIONAL):
/// ```dart
/// // No FindPeopleController:
/// int _displayedCount = 20;
/// bool get hasMore => _displayedCount < _visibleIds.length;
/// List<User> get displayedUsers => users.value.take(_displayedCount).toList();
/// 
/// void loadMore() {
///   if (!hasMore) return;
///   _displayedCount = min(_displayedCount + 20, _visibleIds.length);
///   notifyListeners();
/// }
/// 
/// // Na UI:
/// InfiniteListView(
///   controller: _scrollController,
///   itemCount: controller.displayedUsers.length,
///   itemBuilder: (context, index) {
///     final user = controller.displayedUsers[index];
///     return UserCard(
///       key: ValueKey(user.userId),
///       userId: user.userId,
///       user: user,
///       overallRating: user.overallRating,
///     );
///   },
///   separatorBuilder: (_, __) => const SizedBox(height: 12),
///   onLoadMore: controller.loadMore,
///   isLoadingMore: false, // Já está tudo em memória
///   exhausted: !controller.hasMore,
///   padding: const EdgeInsets.all(20),
/// )
/// ```

/// ═══════════════════════════════════════════════════════════════════
/// 4️⃣ RANKING TAB (People & Places)
/// ═══════════════════════════════════════════════════════════════════
/// 
/// BENEFÍCIO:
/// - Rankings podem ter 100+ itens
/// - Paginar melhora scroll performance
/// - Windowing virtual (só renderiza visíveis)
/// 
/// IMPLEMENTAÇÃO:
/// ```dart
/// // No PeopleRankingState:
/// int _displayedCount = 30;
/// List<PeopleRanking> get displayedRankings {
///   final filtered = master.where((r) => visibleIds.contains(r.userId)).toList();
///   return filtered.take(_displayedCount).toList();
/// }
/// 
/// bool get hasMore => _displayedCount < visibleIds.length;
/// 
/// void loadMore() {
///   if (!hasMore) return;
///   _displayedCount = min(_displayedCount + 30, visibleIds.length);
///   notifyListeners();
/// }
/// 
/// // Na UI (_buildPeopleRankingList):
/// InfiniteListView(
///   controller: _scrollController,
///   itemCount: _peopleState.displayedRankings.length,
///   itemBuilder: (context, index) {
///     final ranking = _peopleState.displayedRankings[index];
///     return PeopleRankingCard(
///       key: ValueKey(ranking.userId),
///       ranking: ranking,
///     );
///   },
///   separatorBuilder: (_, __) => const SizedBox(height: 12),
///   onLoadMore: _peopleState.loadMore,
///   isLoadingMore: false,
///   exhausted: !_peopleState.hasMore,
///   padding: const EdgeInsets.all(16),
/// )
/// ```

/// ═══════════════════════════════════════════════════════════════════
/// 5️⃣ LIST DRAWER (Eventos no Mapa)
/// ═══════════════════════════════════════════════════════════════════
/// 
/// BENEFÍCIO:
/// - Se houver muitos eventos (30+), melhor paginar
/// - Bottom sheet com scroll suave
/// - Melhor performance no mapa
/// 
/// IMPLEMENTAÇÃO (OPCIONAL):
/// ```dart
/// // No ListDrawerController:
/// int _displayedMyEvents = 10;
/// int _displayedNearbyEvents = 10;
/// 
/// List<QueryDocumentSnapshot> get displayedMyEvents {
///   return myEvents.value.take(_displayedMyEvents).toList();
/// }
/// 
/// bool get hasMoreMyEvents => _displayedMyEvents < myEvents.value.length;
/// 
/// void loadMoreMyEvents() {
///   if (!hasMoreMyEvents) return;
///   _displayedMyEvents = min(_displayedMyEvents + 10, myEvents.value.length);
///   notifyListeners();
/// }
/// 
/// // Na UI:
/// InfiniteListView(
///   controller: _myEventsScrollController,
///   itemCount: controller.displayedMyEvents.length,
///   itemBuilder: (context, index) {
///     final eventDoc = controller.displayedMyEvents[index];
///     return _EventCardWrapper(
///       key: ValueKey('my_${eventDoc.id}'),
///       eventId: eventDoc.id,
///       onEventTap: () => _handleEventTap(context, eventDoc.id),
///     );
///   },
///   onLoadMore: controller.loadMoreMyEvents,
///   isLoadingMore: false,
///   exhausted: !controller.hasMoreMyEvents,
///   shrinkWrap: true,
///   physics: const NeverScrollableScrollPhysics(),
/// )
/// ```

/// ═══════════════════════════════════════════════════════════════════
/// ❌ TELAS QUE NÃO SE BENEFICIAM
/// ═══════════════════════════════════════════════════════════════════
/// 
/// 1. CONVERSATIONS TAB
///    - Usa real-time stream (não tem paginação)
///    - Quantidade controlada (geralmente < 50 conversas)
///    - ConversationStreamWidget já é otimizado
/// 
/// 2. ACTIONS TAB
///    - Lista pequena (< 20 itens geralmente)
///    - Streams separados (applications + reviews)
///    - Não precisa de paginação
/// 
/// ═══════════════════════════════════════════════════════════════════
/// 🎯 RESUMO - QUANDO USAR InfiniteListView
/// ═══════════════════════════════════════════════════════════════════
/// 
/// ✅ USE quando:
///    - Lista pode crescer muito (50+ itens)
///    - Dados vêm de query Firestore paginada
///    - Quer scroll infinito automático
///    - Performance de scroll é crítica
/// 
/// ❌ NÃO USE quando:
///    - Lista sempre pequena (< 30 itens)
///    - Real-time stream sem paginação
///    - Custom scroll behavior necessário
///    - Dados já estão todos em memória e são poucos
/// 
/// ═══════════════════════════════════════════════════════════════════
/// 📊 PERFORMANCE ESPERADA
/// ═══════════════════════════════════════════════════════════════════
/// 
/// SEM InfiniteListView (lista completa):
/// - 100 itens = ~300ms para renderizar
/// - Scroll lag com 50+ itens
/// - Memory footprint alto
/// 
/// COM InfiniteListView (paginado):
/// - 20 itens iniciais = ~80ms
/// - Scroll suave sempre
/// - Memory footprint controlado
/// - Loading incremental transparente
/// 
/// ═══════════════════════════════════════════════════════════════════
