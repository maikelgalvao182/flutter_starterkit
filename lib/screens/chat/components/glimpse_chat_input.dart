import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:partiu/core/constants/constants.dart';

/// Componente de entrada de texto para a tela de chat no estilo do Glimpse
class GlimpseChatInput extends StatefulWidget {

  const GlimpseChatInput({
    required this.textController, required this.isBlocked, required this.blockedMessage, required this.onSendText, required this.onSendImage, super.key,
  });
  final TextEditingController textController;
  final bool isBlocked;
  final String blockedMessage;
  final Function(String) onSendText;
  final Function() onSendImage;

  @override
  State<GlimpseChatInput> createState() => _GlimpseChatInputState();
}

class _GlimpseChatInputState extends State<GlimpseChatInput> {
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    final text = widget.textController.text;
    if (_isComposing != text.trim().isNotEmpty) {
      setState(() {
        _isComposing = text.trim().isNotEmpty;
      });
    }
  }

  void _sendTextMessage() {
    final text = widget.textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendText(text);
      widget.textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final i18n = AppLocalizations.of(context);

    if (widget.isBlocked) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Text(
          widget.blockedMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
      );
    }

    // Detecta se o teclado está aberto
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          16, 
          8, 
          16, 
          isKeyboardOpen ? 8 : 16, // Reduz margem inferior quando teclado está aberto
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: GlimpseColors.lightTextField,
        ),
        child: Row(
          children: [
          // Botão de anexo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              icon: Icon(
                Iconsax.attach_circle,
                size: 28,
                color: _isComposing
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).hintColor,
              ),
              iconSize: 28,
              splashRadius: 24,
              onPressed: widget.onSendImage,
            ),
          ),
          // Campo de texto
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(),
              child: TextField(
                controller: widget.textController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: i18n.translate('type_a_message'),
                  hintStyle: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: GlimpseColors.textSubTitle,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                ),
              ),
            ),
          ),
          // Botão de enviar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              icon: Icon(
                Iconsax.send_2,
                size: 28,
                color: _isComposing
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).hintColor,
              ),
              iconSize: 28,
              splashRadius: 24,
              onPressed: _isComposing ? _sendTextMessage : null,
            ),
          ),
          ],
        ),
      ),
    );
  }
}
