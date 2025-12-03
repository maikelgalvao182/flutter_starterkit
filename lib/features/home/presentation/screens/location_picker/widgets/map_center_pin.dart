import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

/// Pin personalizado fixo no centro do mapa
class MapCenterPin extends StatelessWidget {
  const MapCenterPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          child: Icon(
            Iconsax.location5,
            size: 48,
            color: GlimpseColors.primary,
          ),
        ),
        Container(
          width: 4,
          height: 8,
          decoration: BoxDecoration(
            color: GlimpseColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
