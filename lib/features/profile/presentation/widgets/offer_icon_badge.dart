import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Widget reutilizável para o ícone circular das ofertas
/// Usado tanto na visualização quanto na edição de ofertas
class OfferIconBadge extends StatelessWidget {

  const OfferIconBadge({
    required this.color, required this.colorIndex, super.key,
    this.size = 48,
  });
  final Color color;
  final int colorIndex;
  final double size;

  // Ícones variados para os cards (rotação de 3)
  static const List<IconData> _cardIcons = [
    Iconsax.discount_shape, // Verde
    Iconsax.gift,           // Azul
    Iconsax.star,           // Roxo
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _cardIcons[colorIndex % _cardIcons.length],
        color: Colors.white,
        size: size * 0.5, // Ícone proporcional ao tamanho do badge
      ),
    );
  }
}
