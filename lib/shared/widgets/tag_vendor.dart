import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

/// Widget de tag para exibição de categorias de vendor
class TagVendor extends StatelessWidget {
  final String label;
  final String? value;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const TagVendor({
    super.key,
    required this.label,
    this.value,
    this.isSelected = false,
    this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Quando selecionado: borda 1px primary + fundo primaryLight
    // Quando não selecionado: borda cinza + fundo transparente
    final borderColor = isSelected
        ? GlimpseColors.primary
        : Colors.grey.shade300;

    final bgColor = isSelected
        ? GlimpseColors.primaryLight
        : Colors.transparent;

    final txtColor = isSelected
        ? Colors.black
        : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? txtColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
