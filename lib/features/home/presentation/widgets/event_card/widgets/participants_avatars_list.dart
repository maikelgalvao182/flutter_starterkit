import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/shared/widgets/AnimatedSlideIn.dart';
import 'package:partiu/shared/widgets/stable_avatar.dart';

/// Widget burro que exibe lista horizontal de avatares dos participantes
class ParticipantsAvatarsList extends StatelessWidget {
  const ParticipantsAvatarsList({
    required this.participants,
    required this.remainingCount,
    required this.creatorId,
    super.key,
  });

  final List<Map<String, dynamic>> participants;
  final int remainingCount;
  final String? creatorId;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatares com nomes
            for (int i = 0; i < participants.length; i++)
              AnimatedSlideIn(
                delay: Duration(milliseconds: i * 100),
                offsetX: 60.0,
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: _ParticipantItem(
                    participant: participants[i],
                    isCreator: participants[i]['userId'] == creatorId,
                  ),
                ),
              ),
            
            // Contador de participantes restantes
            if (remainingCount > 0)
              AnimatedSlideIn(
                delay: Duration(milliseconds: participants.length * 100),
                offsetX: 60.0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _RemainingCounter(count: remainingCount),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Item individual de participante (avatar + nome)
class _ParticipantItem extends StatelessWidget {
  const _ParticipantItem({
    required this.participant,
    required this.isCreator,
  });

  final Map<String, dynamic> participant;
  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar
              StableAvatar(
                userId: participant['userId'] as String,
                photoUrl: participant['photoUrl'] as String?,
                size: 40,
                borderRadius: BorderRadius.circular(999),
                enableNavigation: true,
              ),
              
              // Badge para criador
              if (isCreator)
                const Positioned(
                  bottom: -2,
                  right: 0,
                  child: _CreatorBadge(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Nome
        SizedBox(
          width: 50,
          child: Text(
            participant['fullName'] as String? ?? 'Anônimo',
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: GlimpseColors.textSubTitle,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Badge dot para identificar o criador
class _CreatorBadge extends StatelessWidget {
  const _CreatorBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: GlimpseColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
    );
  }
}

/// Contador de participantes restantes (+X)
class _RemainingCounter extends StatelessWidget {
  const _RemainingCounter({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GlimpseColors.lightTextField,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '+$count',
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GlimpseColors.textSubTitle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Espaço vazio para alinhar com os nomes
        const SizedBox(
          width: 50,
          height: 17,
        ),
      ],
    );
  }
}
