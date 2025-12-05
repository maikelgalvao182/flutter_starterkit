import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/home/data/models/pending_application_model.dart';
import 'package:partiu/features/home/data/repositories/event_application_repository.dart';
import 'package:partiu/features/home/presentation/widgets/animated_removal_wrapper.dart';
import 'package:partiu/shared/widgets/glimpse_button.dart';
import 'package:partiu/shared/widgets/stable_avatar.dart';

/// Card para aprovação de aplicações pendentes
/// 
/// Exibe:
/// - Avatar do usuário
/// - Nome + "quer participar do" + activityText
/// - Tempo relativo (há X minutos)
/// - Botões: Aceitar (verde) e Recusar (vermelho)
class ApproveCard extends StatefulWidget {
  const ApproveCard({
    required this.application,
    super.key,
  });

  final PendingApplicationModel application;

  @override
  State<ApproveCard> createState() => _ApproveCardState();
}

class _ApproveCardState extends State<ApproveCard> {
  final EventApplicationRepository _repo = EventApplicationRepository();
  final GlobalKey<AnimatedRemovalWrapperState> _animationKey = GlobalKey();
  bool _isProcessing = false;

  Future<void> _handleApprove() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Anima remoção primeiro
      await _animationKey.currentState?.animateRemoval();
      
      // Depois aprova no backend
      await _repo.approveApplication(widget.application.applicationId);
      debugPrint('✅ Aplicação aprovada: ${widget.application.applicationId}');
    } catch (e) {
      debugPrint('❌ Erro ao aprovar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao aprovar solicitação'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleReject() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Anima remoção primeiro
      await _animationKey.currentState?.animateRemoval();
      
      // Depois rejeita no backend
      await _repo.rejectApplication(widget.application.applicationId);
      debugPrint('❌ Aplicação rejeitada: ${widget.application.applicationId}');
    } catch (e) {
      debugPrint('❌ Erro ao rejeitar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao rejeitar solicitação'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRemovalWrapper(
      key: _animationKey,
      onRemove: () {
        // Callback vazio - a remoção real acontece via Stream
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: GlimpseColors.borderColorLight,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Avatar
          StableAvatar(
            userId: widget.application.userId,
            photoUrl: widget.application.userPhotoUrl,
            size: 48,
            borderRadius: BorderRadius.circular(8),
            enableNavigation: true,
          ),

          const SizedBox(width: 12),

          // Informações e Botões
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nome + texto
                _NameText(
                  fullName: widget.application.userFullName,
                  activityText: widget.application.activityText,
                  emoji: widget.application.eventEmoji,
                ),

                const SizedBox(height: 4),

                // Tempo relativo
                Text(
                  widget.application.timeAgo,
                  style: GoogleFonts.getFont(
                    FONT_PLUS_JAKARTA_SANS,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: GlimpseColors.textSubTitle,
                  ),
                ),

                const SizedBox(height: 12),

                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: GlimpseButton(
                        text: 'Aceitar',
                        backgroundColor: GlimpseColors.approveButtonColor,
                        height: 38,
                        fontSize: 14,
                        noPadding: true,
                        isProcessing: _isProcessing,
                        onPressed: _handleApprove,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlimpseButton(
                        text: 'Recusar',
                        backgroundColor: GlimpseColors.rejectButtonColor,
                        height: 38,
                        fontSize: 14,
                        noPadding: true,
                        isProcessing: _isProcessing,
                        onPressed: _handleReject,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Widget const para texto formatado
class _NameText extends StatelessWidget {
  const _NameText({
    required this.fullName,
    required this.activityText,
    required this.emoji,
  });

  final String fullName;
  final String activityText;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: GoogleFonts.getFont(
          FONT_PLUS_JAKARTA_SANS,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: GlimpseColors.primaryColorLight,
        ),
        children: [
          TextSpan(
            text: fullName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(text: ' quer '),
          TextSpan(text: '$emoji $activityText'),
        ],
      ),
    );
  }
}
