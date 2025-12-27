import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/features/home/presentation/widgets/category/activity_category.dart';

/// Widget de seleção de categoria em grid 2 colunas
class CategorySelector extends StatelessWidget {
  const CategorySelector({
    required this.selectedCategory,
    required this.onCategorySelected,
    super.key,
  });

  final ActivityCategory? selectedCategory;
  final ValueChanged<ActivityCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: activityCategories.length,
      itemBuilder: (context, index) {
        final categoryInfo = activityCategories[index];
        final isSelected = selectedCategory == categoryInfo.category;
        
        return _CategoryCard(
          categoryInfo: categoryInfo,
          isSelected: isSelected,
          onTap: () => onCategorySelected(categoryInfo.category),
        );
      },
    );
  }
}

/// Card individual de categoria
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.categoryInfo,
    required this.isSelected,
    required this.onTap,
  });

  final ActivityCategoryInfo categoryInfo;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? GlimpseColors.primaryLight
              : GlimpseColors.lightTextField,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: GlimpseColors.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji
            Text(
              categoryInfo.emoji,
              style: const TextStyle(fontSize: 28),
            ),

            const SizedBox(height: 8),

            // Título
            Text(
              i18n.translate(categoryInfo.titleKey),
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: GlimpseColors.primaryColorLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 2),
            
            // Subtítulo
            Text(
              i18n.translate(categoryInfo.subtitleKey),
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: GlimpseColors.textSubTitle,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
