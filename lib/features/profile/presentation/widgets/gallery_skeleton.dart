import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:shimmer/shimmer.dart';

class GallerySkeleton extends StatelessWidget {
  const GallerySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? GlimpseColors.darkTextField : GlimpseColors.lightTextField;
    
    return GridView.builder(
      physics: const ScrollPhysics(),
      itemCount: 9,
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 4 / 5,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: backgroundColor,
          highlightColor: (isDark 
              ? GlimpseColors.darkTextField.withValues(alpha: 0.7)
              : GlimpseColors.lightTextField.withValues(alpha: 0.7)),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      },
    );
  }
}
