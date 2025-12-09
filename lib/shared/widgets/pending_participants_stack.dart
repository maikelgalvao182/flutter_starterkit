import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/shared/widgets/stable_avatar.dart';

/// Widget compartilhado para exibir avatares empilhados com nomes
/// Usado para mostrar participantes restantes na avaliação
class PendingParticipantsStack extends StatelessWidget {
  final List<Map<String, String>> participants;
  final double avatarSize;
  final int maxVisible;

  const PendingParticipantsStack({
    required this.participants,
    this.avatarSize = 24.0,
    this.maxVisible = 3,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) return const SizedBox.shrink();

    final visibleParticipants = participants.take(maxVisible).toList();
    final remainingCount = participants.length - maxVisible;
    
    // Calcular largura total necessária
    const double overlap = 12.0;
    final stackWidth = avatarSize + ((visibleParticipants.length - 1) * overlap);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GlimpseColors.lightTextField,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatares empilhados
          SizedBox(
            width: stackWidth,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < visibleParticipants.length; i++)
                  Positioned(
                    left: i * overlap,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: StableAvatar(
                        userId: participants[i]['id']!,
                        photoUrl: participants[i]['photoUrl'],
                        size: avatarSize,
                        enableNavigation: false,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Texto explicativo
          Flexible(
            child: Text(
              _buildText(remainingCount),
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GlimpseColors.primaryColorLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _buildText(int remaining) {
    if (participants.length == 1) {
      return 'Falta avaliar ${participants.first['name']}';
    }
    
    final firstName = participants.first['name']?.split(' ').first ?? '';
    
    if (remaining > 0) {
      return 'Falta $firstName e +$remaining';
    }
    
    return 'Falta avaliar $firstName e outros';
  }
}
