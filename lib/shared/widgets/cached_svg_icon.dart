import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget otimizado para SVGs com cache para melhor performance
/// Implementa as boas práticas de performance para assets SVG
class CachedSvgIcon extends StatelessWidget {

  const CachedSvgIcon(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.semanticsLabel,
  });
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SvgPicture.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        colorFilter: color != null 
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        semanticsLabel: semanticsLabel,
        placeholderBuilder: (BuildContext context) => Container(
          width: width,
          height: height,
          color: Colors.transparent,
        ),
      ),
    );
  }
}
