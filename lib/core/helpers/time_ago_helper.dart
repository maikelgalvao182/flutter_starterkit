import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Helper centralizado para formatação de "time ago" (tempo relativo)
/// 
/// Suporta:
/// - Timestamp do Firestore e DateTime
/// - Múltiplos locales (en, pt, es)
/// - Abreviações opcionais (minutes → min, minutos → min)
/// - Comportamento consistente em toda a aplicação
/// 
/// Exemplos:
/// ```dart
/// // Com abreviações (padrão)
/// TimeAgoHelper.format(timestamp: myTimestamp) // "5 min ago"
/// 
/// // Sem abreviações
/// TimeAgoHelper.format(timestamp: myTimestamp, abbreviated: false) // "5 minutes ago"
/// 
/// // Com locale específico
/// TimeAgoHelper.format(timestamp: myTimestamp, locale: 'pt') // "há 5 min"
/// ```
class TimeAgoHelper {
  
  /// Formata timestamp em texto "time ago" (tempo relativo)
  /// 
  /// [timestamp] - Timestamp do Firestore ou DateTime
  /// [locale] - Locale para formatação ('en', 'pt', 'es'). Se null, usa AppLocalizations.currentLocale
  /// [abbreviated] - Se true, abrevia "minutes" → "min", "minutos" → "min" (padrão: true)
  /// 
  /// Retorna:
  /// - String formatada (ex: "5 min ago", "há 5 min", "hace 5 min")
  /// - String vazia se timestamp for inválido
  static String format({
    required dynamic timestamp,
    String? locale,
    bool abbreviated = true,
  }) {
    // Detectar locale (ordem: parâmetro > AppLocalizations > fallback 'en')
    final effectiveLocale = locale ?? 
      AppLocalizations.currentLocale ?? 'en';
    
    // Converter timestamp para DateTime
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp == null) {
      return '';
    } else {
      // Tipo não suportado
      return '';
    }
    
    // Formatar usando biblioteca timeago
    var formatted = timeago.format(dateTime, locale: effectiveLocale);
    
    // Aplicar abreviações se solicitado
    if (abbreviated) {
      formatted = _applyAbbreviations(formatted);
    }
    
    return formatted;
  }
  
  /// Aplica abreviações multilíngue para palavras comuns
  /// 
  /// Substitui:
  /// - 🇺🇸 "minutes" / "minute" → "min"
  /// - 🇧🇷 "minutos" / "minuto" → "min"
  /// - 🇪🇸 "minutos" / "minuto" → "min"
  static String _applyAbbreviations(String text) {
    final replacements = <String, String>{
      // English
      'minutes': 'min',
      'minute': 'min',
      'Minutes': 'min',
      'Minute': 'min',
      // Portuguese
      'minutos': 'min',
      'minuto': 'min',
      'Minutos': 'min',
      'Minuto': 'min',
    };
    
    var result = text;
    replacements.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    
    return result;
  }
  
  /// Formata timestamp com abreviações (atalho)
  /// 
  /// Equivalente a: `format(timestamp: timestamp, abbreviated: true)`
  static String formatAbbreviated(dynamic timestamp, {String? locale}) {
    return format(timestamp: timestamp, locale: locale);
  }
  
  /// Formata timestamp sem abreviações (atalho)
  /// 
  /// Equivalente a: `format(timestamp: timestamp, abbreviated: false)`
  static String formatFull(dynamic timestamp, {String? locale}) {
    return format(timestamp: timestamp, locale: locale, abbreviated: false);
  }
}
