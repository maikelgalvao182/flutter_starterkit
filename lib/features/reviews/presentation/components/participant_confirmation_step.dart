import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';

/// STEP 0 (Owner apenas): Confirmar presença dos participantes
class ParticipantConfirmationStep extends StatelessWidget {
  final List<String> participantIds;
  final Map<String, ParticipantProfile> participantProfiles;
  final Set<String> selectedParticipants;
  final Function(String) onToggleParticipant;

  const ParticipantConfirmationStep({
    required this.participantIds,
    required this.participantProfiles,
    required this.selectedParticipants,
    required this.onToggleParticipant,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instrução
        Text(
          'Quem realmente apareceu?',
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: GlimpseColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecione os participantes que compareceram ao evento. Você só poderá avaliar quem você confirmar.',
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 14,
            color: GlimpseColors.textSecondary,
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
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? GlimpseColors.primary.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) => onToggle(),
        secondary: CircleAvatar(
          radius: 24,
          backgroundColor: GlimpseColors.primary.withOpacity(0.2),
          backgroundImage:
              photoUrl != null ? CachedNetworkImageProvider(photoUrl!) : null,
          child: photoUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.getFont(
                    FONT_PLUS_JAKARTA_SANS,
                    fontSize: 18,
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
