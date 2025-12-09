import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholder para NotificationFilter
/// 
/// Exibe chips de loading com altura fixa de 48px
class NotificationFilterShimmer extends StatelessWidget {
  const NotificationFilterShimmer({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.itemCount = 4,
  });
  
  final EdgeInsetsGeometry padding;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, // Altura fixa para manter espaço consistente
      padding: padding,
      child: Shimmer.fromColors(
        baseColor: GlimpseColors.lightTextField,
        highlightColor: Colors.white,
        child: Row(
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                width: 80 + (index * 10.0), // Larguras variadas
                height: 40,
                decoration: BoxDecoration(
                  color: GlimpseColors.lightTextField,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
