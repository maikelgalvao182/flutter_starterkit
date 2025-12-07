import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/shared/widgets/glimpse_text_field.dart';

/// Step de comentário opcional (Step 2)
class CommentStep extends StatelessWidget {
  final TextEditingController controller;

  const CommentStep({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de texto
        GlimpseTextField(
          controller: controller,
          hintText: 'Ex: Foi uma experiência incrível! A pessoa é muito...',
          maxLines: 6,
          maxLength: 500,
        ),
        
        const SizedBox(height: 16),
        
        // Dica
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GlimpseColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: GlimpseColors.info,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Seu comentário será público e ajudará outros usuários',
                  style: GoogleFonts.getFont(
                    FONT_PLUS_JAKARTA_SANS,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: GlimpseColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
