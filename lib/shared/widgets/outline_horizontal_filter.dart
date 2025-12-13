import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/text_styles.dart';

class OutlineHorizontalFilter extends StatelessWidget {
  const OutlineHorizontalFilter({
    super.key,
    required this.values,
    this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: padding,
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(width: 4),
      itemBuilder: (_, i) {
        final item = values[i];
        final isSelected = item == selected;

        return GestureDetector(
          onTap: () => onSelected(isSelected ? null : item),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected ? GlimpseColors.primaryColorLight : GlimpseColors.borderColorLight,
                width: 1.5,
              ),
              color: isSelected ? GlimpseColors.lightTextField : Colors.transparent,
            ),
            child: Text(
              item,
              style: isSelected 
                  ? TextStyles.filterSelected.copyWith(color: GlimpseColors.primaryColorLight)
                  : TextStyles.filterDefault,
            ),
          ),
        );
      },
    );
  }
}
