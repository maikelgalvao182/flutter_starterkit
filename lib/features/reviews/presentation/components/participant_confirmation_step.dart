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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card do Evento
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GlimpseColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: GlimpseColors.primary.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              // Emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  eventEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventTitle,
                      style: GoogleFonts.getFont(
                        FONT_PLUS_JAKARTA_SANS,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: GlimpseColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (eventDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat("d 'de' MMMM, HH:mm", 'pt_BR').format(eventDate!),
                        style: GoogleFonts.getFont(
                          FONT_PLUS_JAKARTA_SANS,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: GlimpseColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Instrução
        Text(
          'Marca aqui quem realmente deu as caras na sua atividade. Só dá pra avaliar quem apareceu de verdade!',
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: GlimpseColors.primaryColorLight,
          ),
        ),
        const SizedBox(height: 24),

        // Lista de participantes
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
          ...participantIds.map((participantId) {
            final profile = participantProfiles[participantId];
            final isSelected = selectedParticipants.contains(participantId);

            return ParticipantCheckboxTile(
              participantId: participantId,
              name: profile?.name ?? 'Usuário',
              photoUrl: profile?.photoUrl,
              isSelected: isSelected,
              onToggle: () => onToggleParticipant(participantId),
            );
          }),
      ],
    );
  }
}

class ParticipantCheckboxTile extends StatelessWidget {
  final String participantId;
  final String name;
  final String? photoUrl;
  final bool isSelected;
  final VoidCallback onToggle;

  const ParticipantCheckboxTile({
    required this.participantId,
    required this.name,
    required this.photoUrl,
    required this.isSelected,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? GlimpseColors.primary
              : GlimpseColors.borderColorLight,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? GlimpseColors.primary.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) => onToggle(),
        contentPadding: const EdgeInsets.only(
          left: 12,
          right: 4,
          top: 8,
          bottom: 8,
        ),
        secondary: CircleAvatar(
          radius: 28,
          backgroundColor: GlimpseColors.primary.withOpacity(0.2),
          backgroundImage:
              photoUrl != null ? CachedNetworkImageProvider(photoUrl!) : null,
          child: photoUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.getFont(
                    FONT_PLUS_JAKARTA_SANS,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: GlimpseColors.primary,
                  ),
                )
              : null,
        ),
        title: Text(
          name,
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: GlimpseColors.textPrimary,
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: GlimpseColors.primary,
      ),
    );
  }
}
