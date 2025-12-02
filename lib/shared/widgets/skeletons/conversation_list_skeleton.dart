import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

class ConversationListSkeleton extends StatelessWidget {
  const ConversationListSkeleton({super.key, this.itemCount = 10});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (_, __) => const _ConversationSkeletonTile(),
      ),
    );
  }
}

class _ConversationSkeletonTile extends StatelessWidget {
  const _ConversationSkeletonTile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: GlimpseColors.lightTextField,
                borderRadius: _r27,
              ),
            ),

            const SizedBox(width: 14),

            // Name + last message
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(width: 180, height: 14, radius: _r6),
                  SizedBox(height: 8),
                  _Bar(width: 140, height: 12, radius: _r6),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Time indicator
            const _Bar(width: 20, height: 12, radius: _r4),
          ],
        ),
      ),
    );
  }
}

/// Reusable bar widget (replace ShimmerBox)
class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.radius});
  final double width;
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: GlimpseColors.lightTextField,
        borderRadius: radius,
      ),
    );
  }
}

// BorderRadius constantes reutilizáveis
const BorderRadius _r27 = BorderRadius.all(Radius.circular(27));
const BorderRadius _r6 = BorderRadius.all(Radius.circular(6));
const BorderRadius _r4 = BorderRadius.all(Radius.circular(4));
