import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/screens/chat/models/user_model.dart';
import 'package:partiu/screens/chat/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:partiu/core/constants/constants.dart';

class UserPresenceStatusWidget extends StatefulWidget {

  const UserPresenceStatusWidget({
    required this.userId, 
    required this.chatService, 
    super.key,
    this.isEvent = false,
    this.eventId,
  });
  final String userId;
  final ChatService chatService;
  final bool isEvent;
  final String? eventId;

  @override
  State<UserPresenceStatusWidget> createState() => _UserPresenceStatusWidgetState();
}

class _UserPresenceStatusWidgetState extends State<UserPresenceStatusWidget> {
  // A3.2: Cache para formatação de tempo (otimização de performance)
  final Map<DateTime, String> _timeFormatCache = {};
  String? _cachedLocale;

  // A3.2: Formatação otimizada com cache
  String _formatTimeAgo(DateTime dateTime, String locale) {
    // Always use English locale for consistency
    const fixedLocale = 'en';
    
    // Cache invalidation se locale mudou
    if (_cachedLocale != null && _cachedLocale != fixedLocale) {
      _timeFormatCache.clear();
    }
    _cachedLocale = fixedLocale;

    // Verificar cache primeiro
    if (_timeFormatCache.containsKey(dateTime)) {
      return _timeFormatCache[dateTime]!;
    }

    // Formatar e cachear - sempre em inglês
    final formattedTime = timeago.format(
      dateTime,
      locale: fixedLocale,
      allowFromNow: true,
    );
    
    _timeFormatCache[dateTime] = formattedTime;
    
    // Limitar tamanho do cache (manter apenas últimas 50 entradas)
    if (_timeFormatCache.length > 50) {
      final oldestKey = _timeFormatCache.keys.first;
      _timeFormatCache.remove(oldestKey);
    }
    
    return formattedTime;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    // Para eventos, retorna apenas o activityText da coleção events
    if (widget.isEvent && widget.eventId != null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const SizedBox();
          }
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final activityText = data?['activityText'] ?? data?['activity_text'] ?? '';
          
          if (activityText.isEmpty) return const SizedBox();
          
          return Text(
            activityText,
            style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: GlimpseColors.textSubTitle,
            ),
            overflow: TextOverflow.ellipsis,
          );
        },
      );
    }
    
    // Para usuários normais, mantém a lógica original
    return StreamBuilder<UserModel>(
      stream: widget.chatService.getUserUpdates(widget.userId),
      builder: (context, snapshot) {
        // Check data
        if (!snapshot.hasData) return const SizedBox();

        // Get user presence status
        final user = snapshot.data!;

        // Check user presence status
        if (user.isOnline ?? false) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                i18n.translate('ONLINE'),
                style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: GlimpseColors.textSubTitle,
                ),
              ),
            ],
          );
        }
        
        // Verificar último login
        final lastLogin = user.lastLogin;
        if (lastLogin == null) {
          return Text(
            i18n.translate('offline'),
            style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: GlimpseColors.textSubTitle,
            ),
            overflow: TextOverflow.ellipsis,
          );
        }

        // A3.2: Usar formatação otimizada com cache
        final timeAgo = _formatTimeAgo(lastLogin, i18n.translate('lang'));

        // Exibir texto sem hífen
        return Text(
          "${i18n.translate('last_seen')} $timeAgo",
          style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: GlimpseColors.textSubTitle,
          ),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
