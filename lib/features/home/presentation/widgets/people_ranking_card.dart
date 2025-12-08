import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/home/data/models/user_ranking_model.dart';
import 'package:partiu/shared/widgets/badge_chip.dart';
import 'package:partiu/shared/widgets/criteria_bars.dart';
import 'package:partiu/shared/widgets/stable_avatar.dart';

/// Card de ranking de pessoa
/// 
/// Exibe:
/// - Posição no ranking
/// - Avatar, nome e localização
/// - Rating geral com total de reviews
/// - Badges com scroll horizontal
/// - Breakdown visual dos critérios
/// - Número de comentários
class PeopleRankingCard extends StatelessWidget {
  const PeopleRankingCard({
    required this.ranking,
    required this.position,
    super.key,
    this.badgesCount = const {},
    this.criteriaRatings = const {},
    this.totalComments = 0,
  });

  final UserRankingModel ranking;
  final int position;
  final Map<String, int> badgesCount;
  final Map<String, double> criteriaRatings;
  final int totalComments;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push('/profile/${ranking.userId}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Posição + Avatar + Nome/Localização + Rating
              _buildHeader(),
              
              // Badges (se existirem)
              if (badgesCount.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildBadges(context),
              ],
              
              // Breakdown de critérios (se existirem)
              if (criteriaRatings.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildCriteriaBreakdown(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: StableAvatar(
                userId: ranking.userId,
                size: 58,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  Padding(
                    padding: const EdgeInsets.only(right: 48),
                    child: Text(
                      ranking.fullName,
                      style: GoogleFonts.getFont(
                        FONT_PLUS_JAKARTA_SANS,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: GlimpseColors.primaryColorLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Localização
                  Text(
                    _getLocationText(),
                    style: GoogleFonts.getFont(
                      FONT_PLUS_JAKARTA_SANS,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: GlimpseColors.textSubTitle,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Rating + Reviews + Comentários
                  _buildRatingSummary(),
                ],
              ),
            ),
          ],
        ),
        
        // Posição no canto direito
        Positioned(
          top: 0,
          right: 0,
          child: _buildPosition(),
        ),
      ],
    );
  }

  Widget _buildPosition() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _getPositionBackgroundColor(),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        position.toString(),
        style: GoogleFonts.getFont(
          FONT_PLUS_JAKARTA_SANS,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: GlimpseColors.primaryColorLight,
        ),
      ),
    );
  }

  Color _getPositionBackgroundColor() {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700).withValues(alpha: 0.15); // Ouro claro
      case 2:
        return const Color(0xFFC0C0C0).withValues(alpha: 0.15); // Prata claro
      case 3:
        return const Color(0xFFCD7F32).withValues(alpha: 0.15); // Bronze claro
      default:
        return Colors.grey.shade100;
    }
  }

  Widget _buildRatingSummary() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Estrela + Rating
        // Nota + Estrela
        Text(
          ranking.overallRating.toStringAsFixed(1),
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: GlimpseColors.textSubTitle,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Iconsax.star1,
          size: 18,
          color: const Color(0xFFFFB800),
        ),
        
        const SizedBox(width: 4),
        
        // Separador
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: GlimpseColors.textSubTitle.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
        
        const SizedBox(width: 4),
        
        // Total de reviews
        Flexible(
          child: Text(
            '${ranking.totalReviews} avaliação${ranking.totalReviews != 1 ? 'ões' : ''}',
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: GlimpseColors.textSubTitle,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Comentários (se houver)
        if (totalComments > 0) ...[
          const SizedBox(width: 4),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: GlimpseColors.textSubTitle.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$totalComments comentário${totalComments != 1 ? 's' : ''}',
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: GlimpseColors.textSubTitle,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBadges(BuildContext context) {
    // Ordenar badges por frequência
    final sortedBadges = badgesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedBadges.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Container(
          height: 1,
          color: GlimpseColors.borderColorLight,
          margin: const EdgeInsets.only(bottom: 12),
        ),
        
        // Badges com scroll horizontal
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sortedBadges.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final entry = sortedBadges[index];
              return BadgeChip(
                badgeKey: entry.key,
                count: entry.value,
                showCount: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCriteriaBreakdown() {
    return CriteriaBars(
      criteriaRatings: criteriaRatings,
      showDivider: true,
    );
  }

  String _getLocationText() {
    if (ranking.locality.isEmpty && (ranking.state ?? '').isEmpty) {
      return 'Localização não informada';
    }
    
    if (ranking.state != null && ranking.state!.isNotEmpty) {
      return '${ranking.locality}, ${ranking.state}';
    }
    
    return ranking.locality;
  }
}
