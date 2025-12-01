import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget para exibir ícones SVG
class SvgIcon extends StatelessWidget {
  final String assetPath;
  final Color? color;
  final double? width;
  final double? height;

  const SvgIcon(
    this.assetPath, {
    super.key,
    this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      width: width,
      height: height,
    );
  }
}
