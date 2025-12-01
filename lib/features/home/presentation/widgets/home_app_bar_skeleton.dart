import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:flutter/material.dart';

/// Skeleton loader para o AppBar enquanto dados do usuário são carregados
class HomeAppBarSkeleton extends StatelessWidget {
  const HomeAppBarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name skeleton
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: GlimpseColors.lightTextField,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        // Location skeleton
        Container(
          width: 80,
          height: 12,
          decoration: BoxDecoration(
            color: GlimpseColors.lightTextField,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
