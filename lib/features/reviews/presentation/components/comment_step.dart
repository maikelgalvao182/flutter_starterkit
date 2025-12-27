import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/shared/widgets/glimpse_text_field.dart';
import 'package:partiu/shared/widgets/pending_participants_stack.dart';

/// Step de comentário opcional (Step 2)
class CommentStep extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final List<Map<String, String>> remainingParticipants;

  const CommentStep({
    required this.controller,
    this.focusNode,
    this.remainingParticipants = const [],
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
          focusNode: focusNode,
          hintText: 'Ex: Foi uma experiência incrível! A pessoa é muito...',
          maxLines: 6,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
        ),
        
        if (remainingParticipants.isNotEmpty) ...[
          const SizedBox(height: 16),
          PendingParticipantsStack(
            participants: remainingParticipants,
          ),
        ],
      ],
    );
  }
}
