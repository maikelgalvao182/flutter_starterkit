import 'package:flutter/material.dart';
import 'dart:async';

/// Widget global reutilizável para listas infinitas com paginação
/// 
/// 🎯 ARQUITETURA SEPARADA:
/// 
/// ✅ Este widget cuida APENAS de UI e comportamento:
///    - Escuta scroll controller
///    - Dispara onLoadMore() próximo ao fim
///    - Exibe loading indicator inferior
///    - Throttle/debounce automático
///    - Preserva posição do scroll
///    - Previne múltiplas chamadas simultâneas
/// 
/// ❌ NÃO gerencia dados/lógica:
///    - Como buscar mais dados (Firestore, API, etc)
///    - Como armazenar cursor/paginação
///    - Como aplicar filtros
///    - Como integrar WebSocket
///    - TTL de dados
///    - Cache strategies
/// 
/// 💡 USO:
/// ```dart
/// InfiniteListView(
///   controller: _scrollController,
///   itemCount: myList.length,
///   itemBuilder: (context, index) => MyTile(myList[index]),
///   onLoadMore: () => myController.loadMore(),
///   isLoadingMore: myController.isLoadingMore,
///   exhausted: myController.exhausted,
/// )
/// ```
/// 
/// 📦 TELAS QUE SE BENEFICIAM:
/// - Notifications (paginação por timestamp)
/// - Profile Visits (lista de visitantes)
/// - Find People (scroll infinito de usuários)
/// - Rankings (listas grandes de rankings)
class InfiniteListView extends StatefulWidget {
  const InfiniteListView({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.onLoadMore,
    this.isLoadingMore = false,
    this.exhausted = false,
    this.loadMoreThreshold = 0.8,
    this.throttleDuration = const Duration(milliseconds: 500),
    this.padding,
    this.separatorBuilder,
    this.physics,
    this.shrinkWrap = false,
  });

  /// ScrollController para controlar a lista
  final ScrollController controller;

  /// Número de itens na lista
  final int itemCount;

  /// Builder para cada item
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Callback quando deve carregar mais dados
  /// A lógica de paginação fica no Controller/ViewModel da tela
  final VoidCallback onLoadMore;

  /// Se está carregando mais dados (mostra loading no fim da lista)
  final bool isLoadingMore;

  /// Se não há mais dados para carregar
  final bool exhausted;

  /// Threshold para disparar loadMore (0.8 = 80% do scroll)
  /// Valores sugeridos: 0.7-0.9
  final double loadMoreThreshold;

  /// Duração do throttle para evitar múltiplas chamadas
  final Duration throttleDuration;

  /// Padding da lista
  final EdgeInsets? padding;

  /// Builder para separadores entre itens
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Physics do scroll
  final ScrollPhysics? physics;

  /// Se deve shrinkWrap
  final bool shrinkWrap;

  @override
  State<InfiniteListView> createState() => _InfiniteListViewState();
}

class _InfiniteListViewState extends State<InfiniteListView> {
  Timer? _throttleTimer;
  bool _isLoadingMoreInternal = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _throttleTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Não fazer nada se já está carregando ou se não há mais dados
    if (_isLoadingMoreInternal || widget.isLoadingMore || widget.exhausted) {
      return;
    }

    // Verificar se está próximo ao fim (threshold configurável)
    final maxScroll = widget.controller.position.maxScrollExtent;
    final currentScroll = widget.controller.offset;
    final threshold = maxScroll * widget.loadMoreThreshold;

    if (currentScroll >= threshold) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    // Throttle: evitar múltiplas chamadas em sequência
    if (_throttleTimer?.isActive ?? false) {
      return;
    }

    _isLoadingMoreInternal = true;
    
    // Chamar callback
    widget.onLoadMore();

    // Throttle timer
    _throttleTimer = Timer(widget.throttleDuration, () {
      _isLoadingMoreInternal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Se não tem separador, usar ListView.builder normal
    if (widget.separatorBuilder == null) {
      return ListView.builder(
        controller: widget.controller,
        padding: widget.padding,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        itemCount: widget.itemCount + (widget.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Último item = loading indicator
          if (index == widget.itemCount) {
            return _buildLoadingIndicator();
          }
          return widget.itemBuilder(context, index);
        },
      );
    }

    // Com separador, usar ListView.separated
    return ListView.separated(
      controller: widget.controller,
      padding: widget.padding,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      itemCount: widget.itemCount + (widget.isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) {
        // Não mostrar separador antes do loading indicator
        if (index == widget.itemCount - 1 && widget.isLoadingMore) {
          return const SizedBox.shrink();
        }
        return widget.separatorBuilder!(context, index);
      },
      itemBuilder: (context, index) {
        // Último item = loading indicator
        if (index == widget.itemCount) {
          return _buildLoadingIndicator();
        }
        return widget.itemBuilder(context, index);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Wrapper para CustomScrollView com SliverList
/// Útil quando você já tem um CustomScrollView e quer adicionar paginação
class InfiniteSliverList extends StatefulWidget {
  const InfiniteSliverList({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.onLoadMore,
    this.isLoadingMore = false,
    this.exhausted = false,
    this.loadMoreThreshold = 0.8,
    this.throttleDuration = const Duration(milliseconds: 500),
  });

  final ScrollController controller;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool exhausted;
  final double loadMoreThreshold;
  final Duration throttleDuration;

  @override
  State<InfiniteSliverList> createState() => _InfiniteSliverListState();
}

class _InfiniteSliverListState extends State<InfiniteSliverList> {
  Timer? _throttleTimer;
  bool _isLoadingMoreInternal = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _throttleTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMoreInternal || widget.isLoadingMore || widget.exhausted) {
      return;
    }

    final maxScroll = widget.controller.position.maxScrollExtent;
    final currentScroll = widget.controller.offset;
    final threshold = maxScroll * widget.loadMoreThreshold;

    if (currentScroll >= threshold) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    if (_throttleTimer?.isActive ?? false) {
      return;
    }

    _isLoadingMoreInternal = true;
    widget.onLoadMore();

    _throttleTimer = Timer(widget.throttleDuration, () {
      _isLoadingMoreInternal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == widget.itemCount) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return widget.itemBuilder(context, index);
        },
        childCount: widget.itemCount + (widget.isLoadingMore ? 1 : 0),
      ),
    );
  }
}
