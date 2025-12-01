import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget de pull-to-refresh com Cupertino spinner em todas as plataformas.
/// Reproduz o comportamento fluido do Instagram:
/// - Spinner suave e com tempo de exibição mínimo (~1s)
/// - Animação de retorno natural
/// - Usa CupertinoSliverRefreshControl para consistência visual
class PlatformPullToRefresh extends StatelessWidget {

  const PlatformPullToRefresh({
    required this.onRefresh, required this.itemCount, required this.itemBuilder, super.key,
    this.physics,
    this.padding,
    this.controller,
    this.storageKey,
    this.refreshIndicatorKey,
    this.addAutomaticKeepAlives = true,
    this.itemExtent,
    this.prototypeItem,
    // Cache invalidation
    this.cacheInvalidationPatterns,
  });
  final Future<void> Function() onRefresh;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final Key? storageKey;
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey; // Não usado - mantido para compatibilidade
  final bool addAutomaticKeepAlives;
  final double? itemExtent; // Não usado no CustomScrollView - mantido para compatibilidade
  final Widget? prototypeItem; // Não usado no CustomScrollView - mantido para compatibilidade
  // [OK] NOVO: Padrões de cache para invalidar no pull-to-refresh
  final List<String>? cacheInvalidationPatterns;

  /// Garante que o spinner fique visível tempo suficiente (mesmo que o refresh seja rápido)
  Future<void> _delayedRefresh(Future<void> Function() refresh) async {
    // Cache invalidation patterns podem ser usados futuramente quando o sistema de cache estiver implementado
    if (cacheInvalidationPatterns != null && 
        cacheInvalidationPatterns!.isNotEmpty && kDebugMode) {
      // AppLogger.debug('ℹ️  [PlatformPullToRefresh] Cache invalidation patterns: $cacheInvalidationPatterns');
    }
    
    final start = DateTime.now();
    await refresh();
    final elapsed = DateTime.now().difference(start);
    if (elapsed < const Duration(milliseconds: 800)) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    // Recuo natural após o término
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Widget build(BuildContext context) {
    // Usa CupertinoSliverRefreshControl em ambas as plataformas para consistência
    return CustomScrollView(
      key: storageKey,
      controller: controller,
      physics: physics ??
          const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => _delayedRefresh(onRefresh),
          refreshTriggerPullDistance: 120,
          refreshIndicatorExtent: 80,
          builder: (context, mode, pulledExtent, triggerDistance, indicatorExtent) {
            final percentage =
                (pulledExtent / triggerDistance).clamp(0.0, 1.0);
            final isRefreshing = mode == RefreshIndicatorMode.refresh ||
                mode == RefreshIndicatorMode.armed;

            // Opacidade e leve movimento vertical para suavizar a entrada/saída
            final spinnerOpacity = isRefreshing ? 1.0 : percentage;
            final spinnerOffset = (1 - percentage) * 20;

            return SizedBox(
              height: pulledExtent,
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, spinnerOffset),
                  child: Opacity(
                    opacity: spinnerOpacity,
                    child: const CupertinoActivityIndicator(radius: 14),
                  ),
                ),
              ),
            );
          },
        ),
        SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: itemCount,
              addAutomaticKeepAlives: addAutomaticKeepAlives,
            ),
          ),
        ),
      ],
    );
  }
}
