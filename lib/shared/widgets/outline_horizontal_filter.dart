import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/text_styles.dart';

/// Filtro horizontal estilo outline com bordas e altura reduzida
/// 
/// Usado para filtros secundários como cidades, categorias, etc.
/// Diferente do NotificationHorizontalFilters que é mais proeminente,
/// este widget usa estilo outline (apenas borda) para hierarquia visual.
/// 
/// Características:
/// - Altura reduzida (38px vs 48px do padrão)
/// - Borda: borderColorLight
/// - Texto: textSubTitle
/// - Selecionado: borda primary + background primary com opacidade
class OutlineHorizontalFilter extends StatelessWidget {
  const OutlineHorizontalFilter({
    super.key,
    required this.values,
    this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.itemSpacing = 8.0,
    this.height = 48.0,
  });

  /// Lista de valores a serem exibidos
  final List<String> values;
  
  /// Valor atualmente selecionado (pode ser null)
  final String? selected;
  
  /// Callback quando um valor é selecionado
  final ValueChanged<String?> onSelected;
  
  /// Padding ao redor do filtro
  final EdgeInsets padding;
  
  /// Espaçamento entre items
  final double itemSpacing;
  
  /// Altura do filtro
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: values.length,
        separatorBuilder: (_, __) => SizedBox(width: itemSpacing),
        itemBuilder: (_, index) {
          final item = values[index];
          final isSelected = item == selected;

          return GestureDetector(
            onTap: () {
              // Se já está selecionado, desseleciona (null)
              // Senão, seleciona o item
              onSelected(isSelected ? null : item);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: itemSpacing / 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected
                        ? GlimpseColors.primary
                        : GlimpseColors.borderColorLight,
                    width: 1.5,
                  ),
                  color: isSelected 
                      ? GlimpseColors.primary.withOpacity(0.08) 
                      : Colors.transparent,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item,
                      style: isSelected
                          ? TextStyles.filterSelected
                          : TextStyles.filterDefault,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
