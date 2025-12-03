import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/features/home/presentation/widgets/event_card/event_card_controller.dart';
import 'package:partiu/shared/widgets/dialogs/dialog_styles.dart';
import 'package:partiu/shared/widgets/emoji_container.dart';
import 'package:partiu/shared/widgets/glimpse_close_button.dart';
import 'package:partiu/shared/widgets/stable_avatar.dart';

/// Card de evento que exibe informações do criador e localização
/// 
/// UI baseada no ProfileCompletenessDialog
class EventCard extends StatefulWidget {
  const EventCard({
    required this.controller,
    required this.onActionPressed,
    super.key,
    this.title,
    this.subtitle,
    this.actionButtonText,
  });

  final EventCardController controller;
  final VoidCallback onActionPressed;
  final String? title;
  final String? subtitle;
  final String? actionButtonText;

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late EventCardController _controller;

  @override
  void initState() {
    super.initState();
    // Usar o controller já carregado passado como parâmetro
    _controller = widget.controller;
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    // NÃO dispose do controller aqui pois ele pode ser usado depois
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Lida com o press do botão baseado no estado atual
  Future<void> _handleButtonPress() async {
    // Se é o criador, mostrar lista de participantes (TODO)
    if (_controller.isCreator) {
      widget.onActionPressed();
      return;
    }

    // Se já foi aprovado, entrar no chat
    if (_controller.isApproved) {
      widget.onActionPressed();
      return;
    }

    // Se ainda não aplicou, aplicar agora
    if (!_controller.hasApplied) {
      try {
        await _controller.applyToEvent();
        
        // Mostrar feedback
        if (mounted) {
          final message = _controller.isApproved
              ? AppLocalizations.of(context).translate('accepted_entering_chat')
              : AppLocalizations.of(context).translate('request_sent_awaiting');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          
          // Se foi auto-aprovado (evento aberto), entrar no chat
          if (_controller.isApproved) {
            widget.onActionPressed();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('error_applying').replaceAll('{error}', e.toString()))),
          );
        }
      }
    }
  }

  /// Formata a data para exibição (hoje, amanhã ou dia específico)
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDay = DateTime(date.year, date.month, date.day);
    
    if (eventDay == today) {
      return 'hoje';
    } else if (eventDay == tomorrow) {
      return 'amanhã';
    } else {
      return 'dia ${DateFormat('dd/MM').format(date)}';
    }
  }

  /// Formata o horário para exibição (apenas se for horário específico)
  String _formatTime(DateTime? date) {
    if (date == null) return '';
    
    // Se for meia-noite exata (00:00), significa que é flexible (só data)
    if (date.hour == 0 && date.minute == 0) {
      return '';
    }
    
    // Caso contrário, mostrar o horário formatado
    return DateFormat('HH:mm').format(date);
  }

  /// Constrói texto formatado em uma única linha corrida com quebra:
  /// "fullName quer activityText em locationName, no dia date às horário"
  Widget _buildFormattedText() {
    final fullName = _controller.creatorFullName ?? '';
    final activityText = _controller.activityText ?? '';
    final locationName = _controller.locationName ?? '';
    final scheduleDate = _controller.scheduleDate;
    
    final dateText = scheduleDate != null ? _formatDate(scheduleDate) : '';
    final timeText = scheduleDate != null ? _formatTime(scheduleDate) : '';

    return RichText(
      textAlign: TextAlign.center,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: GoogleFonts.getFont(
          FONT_PLUS_JAKARTA_SANS,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        children: [
          // Parte 1: Nome + Atividade
          TextSpan(
            text: fullName,
            style: const TextStyle(color: GlimpseColors.primary),
          ),
          const TextSpan(
            text: ' quer ',
            style: TextStyle(color: GlimpseColors.textSubTitle),
          ),
          TextSpan(
            text: activityText,
            style: const TextStyle(color: GlimpseColors.primaryColorLight),
          ),
          
          // Parte 2: Local + Data + Horário (se houver data)
          if (scheduleDate != null) ...[
            const TextSpan(
              text: ' ',
            ),
            const TextSpan(
              text: 'em ',
              style: TextStyle(
                color: GlimpseColors.textSubTitle,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: locationName,
              style: const TextStyle(
                color: GlimpseColors.primary,
                decoration: TextDecoration.underline,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (dateText.isNotEmpty) ...[
              TextSpan(
                text: dateText.startsWith('dia ') ? ', no ' : ', ',
                style: const TextStyle(
                  color: GlimpseColors.textSubTitle,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: dateText,
                style: const TextStyle(
                  color: GlimpseColors.textSubTitle,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (timeText.isNotEmpty) ...[
              const TextSpan(
                text: ' às ',
                style: TextStyle(
                  color: GlimpseColors.textSubTitle,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: timeText,
                style: const TextStyle(
                  color: GlimpseColors.textSubTitle,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Constrói o contador de participantes com estilo de chip
  Widget _buildParticipantsCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GlimpseColors.primaryLight,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '${_controller.participantsCount} ${_controller.participantsCount == 1 ? AppLocalizations.of(context).translate('participant_singular') : AppLocalizations.of(context).translate('participant_plural')}',
        style: GoogleFonts.getFont(
          FONT_PLUS_JAKARTA_SANS,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: GlimpseColors.primaryColorLight,
        ),
      ),
    );
  }

  /// Constrói lista horizontal de avatares dos participantes aprovados
  Widget _buildParticipantsAvatars() {
    if (_controller.approvedParticipants.isEmpty) {
      return const SizedBox.shrink();
    }

    // Mostrar no máximo 5 avatares + contador se houver mais
    final visibleParticipants = _controller.approvedParticipants.take(5).toList();
    final remainingCount = _controller.participantsCount - visibleParticipants.length;

    return Column(
      children: [
        const SizedBox(height: 24), // 24px entre texto e participantes
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatares sobrepostos com nomes
            for (int i = 0; i < visibleParticipants.length; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                child: Column(
                  children: [
                    // Stack para badge de coroa não afetar alinhamento
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Avatar
                          StableAvatar(
                            userId: visibleParticipants[i]['userId'] as String,
                            photoUrl: visibleParticipants[i]['photoUrl'] as String?,
                            size: 40,
                            borderRadius: BorderRadius.circular(999),
                            enableNavigation: true,
                          ),
                          
                          // Badge dot no canto superior direito para o criador
                          if (visibleParticipants[i]['userId'] == _controller.creatorId)
                            Positioned(
                              bottom: -2,
                              right: 0,
                              child: Container(
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
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Nome abaixo do avatar
                    SizedBox(
                      width: 50,
                      child: Text(
                        visibleParticipants[i]['fullName'] as String? ?? 'Anônimo',
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
                ),
              ),
            
            // Contador de participantes restantes
            if (remainingCount > 0) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
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
                          '+$remainingCount',
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
                      height: 17, // Altura aproximada do texto
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(16),
        constraints: const BoxConstraints(
          maxWidth: 500,
          minWidth: 300,
        ),
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                const SizedBox(height: 56), // Espaço para o emoji no topo (40px emoji + 16px espaço)

                // Error state
                if (_controller.error != null)
                  Expanded(
                    child: Center(
                      child: Text(
                        _controller.error!,
                        style: DialogStyles.messageStyle.copyWith(
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )

                // Success state
                else if (_controller.hasData) ...[
                  // Contador de participantes
                  _buildParticipantsCounter(),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle (formatted text)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildFormattedText(),
                  ),
                  
                  // Lista de participantes (avatares)
                  _buildParticipantsAvatars(),
                  
                  const Spacer(),

                  // Action button fixo no bottom
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _controller.isButtonEnabled 
                          ? () => _handleButtonPress() 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlimpseColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: GlimpseColors.disabledButtonColorLight,
                        disabledForegroundColor: GlimpseColors.textHint,
                        shape: RoundedRectangleBorder(
                          borderRadius: DialogStyles.buttonBorderRadius,
                        ),
                        padding: DialogStyles.buttonPadding,
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate(_controller.buttonText),
                        style: DialogStyles.buttonTextStyle.copyWith(
                          color: _controller.isButtonEnabled 
                              ? Colors.white 
                              : GlimpseColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ] else
                  // No data state
                  Expanded(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('no_data_available'),
                        style: DialogStyles.messageStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Emoji posicionado no topo (sobrepondo o botão fechar)
            Positioned(
              top: -40,
              left: 0,
              right: 0,
              child: Center(
                child: _controller.emoji != null
                    ? EmojiContainer(
                        emoji: _controller.emoji!,
                        size: 80,
                        emojiSize: 40,
                        borderWidth: 6,
                        borderColor: Colors.white,
                      )
                    : const SizedBox(width: 80, height: 80),
              ),
            ),
            
            // Close button no topo direito
            Positioned(
              top: 0,
              right: 0,
              child: GlimpseCloseButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
