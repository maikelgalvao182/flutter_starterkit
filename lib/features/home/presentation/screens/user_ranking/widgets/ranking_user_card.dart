import 'package:dating_app/di/dependency_provider.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/screens/conversation_tab/utils/conversation_styles.dart';
import 'package:dating_app/screens/discover_vendor/services/vendor_navigation_service.dart';
import 'package:dating_app/screens/ranking/models/ranking_entry.dart';
import 'package:dating_app/widgets/reactive/reactive_widgets.dart';
import 'package:dating_app/widgets/stable_avatar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dating_app/constants/constants.dart';

/// Card destacado do usuário atual no ranking
class RankingUserCard extends StatelessWidget {
  const RankingUserCard({
    required this.entry,
    this.onTap,
    super.key,
  });

  final RankingEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3B30), Color(0xFFFF6B58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _navigateToProfile(context),
          borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Posição à esquerda
                  Text(
                    '${entry.position}',
                    style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Avatar
                  StableAvatar(
                    userId: entry.userId,
                    size: 44,
                    borderRadius: BorderRadius.circular(24),
                    enableNavigation: false,
                  ),
                  const SizedBox(width: 12),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i18n.translate('your_position'),
                          style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Nome + Rating
                        Row(
                          children: [
                            Expanded(
                              child: ReactiveUserNameWithBadge(
                                userId: entry.userId,
                                spacing: 4,
                                style: ConversationStyles.title(false).copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (entry.totalReviews > 0) ...[
                              const SizedBox(width: 8),
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
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Reviews count
                        if (entry.totalReviews > 0)
                          Text(
                            '${entry.totalReviews} ${i18n.translate('reviews_count')}',
                            style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToProfile(BuildContext context) async {
    final nav = getIt<VendorNavigationService>();
    await nav.navigateToVendorProfile(
      context: context,
      vendorId: entry.userId,
      vendorName: entry.fullName,
      source: 'ranking_user_card',
      analyticsProps: {
        'position': entry.position,
        'overall_rating': entry.overallRating,
        'total_reviews': entry.totalReviews,
      },
    );
  }
}
