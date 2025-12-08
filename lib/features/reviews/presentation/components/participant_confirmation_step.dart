import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';

/// STEP 0 (Owner apenas): Confirmar presença dos participantes
class ParticipantConfirmationStep extends StatelessWidget {
  final List<String> participantIds;
  final Map<String, ParticipantProfile> participantProfiles;
  final Set<String> selectedParticipants;
  final Function(String) onToggleParticipant;
  final String eventTitle;
  final String eventEmoji;
  final DateTime? eventDate;

  const ParticipantConfirmationStep({
    required this.participantIds,
    required this.participantProfiles,
    required this.selectedParticipants,
    required this.onToggleParticipant,
    required this.eventTitle,
    required this.eventEmoji,
    this.eventDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = eventDate != null
        ? DateFormat("d 'de' MMMM 'às' HH:mm", 'pt_BR').format(eventDate!)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Texto integrado com dados do evento
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: GlimpseColors.primaryColorLight,
            ),
            children: [
              const TextSpan(text: 'Selecione apenas quem apareceu na sua atividade '),
              TextSpan(
                text: eventTitle,
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: GlimpseColors.primary,
                ),
              ),
              TextSpan(
                text: ' $eventEmoji',
                style: const TextStyle(fontSize: 20),
              ),
              if (dateText.isNotEmpty) ...[
                const TextSpan(text: ' no dia '),
                TextSpan(text: dateText),
              ],
              const TextSpan(text: ' e deixe sua avaliação!'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Lista de participantes em grid 3 colunas
        if (participantIds.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Nenhum participante marcou presença',
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 14,
                  color: GlimpseColors.textSecondary,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.95,
            ),
            itemCount: participantIds.length,
            itemBuilder: (context, index) {
              final participantId = participantIds[index];
              final profile = participantProfiles[participantId];
              final isSelected = selectedParticipants.contains(participantId);

              return ParticipantCard(
                participantId: participantId,
                name: profile?.name ?? 'Usuário',
                photoUrl: profile?.photoUrl,
                isSelected: isSelected,
                onTap: () => onToggleParticipant(participantId),
              );
            },
          ),
      ],
    );
  }
}

class ParticipantCard extends StatelessWidget {
  final String participantId;
  final String name;
  final String? photoUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const ParticipantCard({
    required this.participantId,
    required this.name,
    required this.photoUrl,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? GlimpseColors.primary
                : GlimpseColors.borderColorLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? GlimpseColors.primaryLight
              : Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 32,
              backgroundColor: GlimpseColors.primary.withOpacity(0.2),
              backgroundImage:
                  photoUrl != null ? CachedNetworkImageProvider(photoUrl!) : null,
              child: photoUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.getFont(
                        FONT_PLUS_JAKARTA_SANS,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: GlimpseColors.primary,
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(height: 8),
            
            // Nome
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: GlimpseColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
