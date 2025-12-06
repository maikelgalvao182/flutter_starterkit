import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

/// Widget dummy que replica apenas a UI do header de presença
/// sem carregar Firestore ou fazer qualquer operação assíncrona.
/// Elimina flickering visual ao abrir o chat.
class DummyPresenceHeader extends StatelessWidget {
  const DummyPresenceHeader({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          color: GlimpseColors.primaryLight,
          border: Border(
            bottom: BorderSide(
              color: GlimpseColors.primaryLight,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            const Text(
              '🙋',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              'Confirme sua presença',
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GlimpseColors.primaryColorLight,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.expand_more,
              color: GlimpseColors.primaryColorLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
