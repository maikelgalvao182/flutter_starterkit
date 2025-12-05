import 'package:dating_app/constants/glimpse_colors.dart';
import 'package:dating_app/di/dependency_provider.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/screens/conversation_tab/utils/conversation_styles.dart';
import 'package:dating_app/screens/discover_vendor/services/vendor_navigation_service.dart';
import 'package:dating_app/screens/discover_vendor/widgets/touchable_opacity.dart';
import 'package:dating_app/screens/ranking/models/ranking_entry.dart';
import 'package:dating_app/widgets/reactive/reactive_widgets.dart';
import 'package:dating_app/widgets/stable_avatar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dating_app/constants/constants.dart';

/// Widget reutilizável para exibir um vendor no pódio do ranking
/// 
/// Layout igual ao RankingCard mas com borda e fundo coloridos (ouro/prata/bronze)
class WinnerPodiumCard extends StatelessWidget {
  const WinnerPodiumCard({
    required this.entry,
    super.key,
  });

  final RankingEntry entry;

  // Cores baseadas na posição
  Color get _borderColor {
    switch (entry.position) {
      case 1:
        return const Color(0xFFEFBF04); // Ouro
      case 2:
        return const Color(0xFF9E9E9E); // Prata escurecida
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  Color get _backgroundColor {
    switch (entry.position) {
      case 1:
        return const Color(0xFFEFBF04).withValues(alpha: 0.05); // Fundo dourado suave
      case 2:
        return const Color(0xFF9E9E9E).withValues(alpha: 0.05); // Fundo prateado escurecido suave
      case 3:
        return const Color(0xFFCD7F32).withValues(alpha: 0.05); // Fundo bronze suave
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TouchableOpacity(
      onTap: () => _navigateToProfile(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _borderColor,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Posição à esquerda com cor do pódio
            Text(
              '${entry.position}',
              style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _borderColor,
              ),
            ),
            const SizedBox(width: 12),
            
            // Avatar
            StableAvatar(
              userId: entry.userId,
              size: 44,
              borderRadius: BorderRadius.circular(8),
              enableNavigation: false,
            ),
            const SizedBox(width: 12),

            // Nome + Location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nome + Rating
                  Row(
                    children: [
                      Expanded(
                        child: ReactiveUserNameWithBadge(
                          userId: entry.userId,
                          spacing: 4,
                          style: ConversationStyles.title(false),
                        ),
                      ),
                      if (entry.totalReviews > 0) ...[
                        const SizedBox(width: 8),
                        _buildRating(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Location + Reviews na mesma row
                  Row(
                    children: [
                      Flexible(
                        child: ReactiveVendorLocationSection(
                          userId: entry.userId,
                          distanceText: null,
                          fontSize: 13,
                        ),
                      ),
                      if (entry.totalReviews > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${entry.totalReviews} ${AppLocalizations.of(context).translate('reviews_count')}',
                          style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: GlimpseColors.subtitleTextColorLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rating com estrela filled
  Widget _buildRating() {
    if (entry.totalReviews == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Iconsax.star1, // Estrela filled
          size: 18,
          color: Color(0xFFFFD700), // Amarelo ouro
        ),
        const SizedBox(width: 4),
        Text(
          entry.overallRating.toStringAsFixed(1),
          style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: GlimpseColors.textColorLight,
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToProfile(BuildContext context) async {
    final nav = getIt<VendorNavigationService>();
    await nav.navigateToVendorProfile(
      context: context,
      vendorId: entry.userId,
      vendorName: entry.fullName,
      source: 'winner_podium_card',
      analyticsProps: {
        'position': entry.position,
        'overall_rating': entry.overallRating,
        'total_reviews': entry.totalReviews,
      },
    );
  }
}
