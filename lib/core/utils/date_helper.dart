import 'package:flutter/material.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Helper para formatação de datas
class DateHelper {
  /// Formata data de forma relativa (ex: "há 2 dias", "há 3 meses")
  static String formatRelativeDate(DateTime date, {required BuildContext context}) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    final i18n = AppLocalizations.of(context);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return i18n.translate('just_now');
        }
        return i18n.translate('minutes_ago').replaceAll('{count}', '${difference.inMinutes}');
      }
      return i18n.translate('hours_ago').replaceAll('{count}', '${difference.inHours}');
    } else if (difference.inDays < 30) {
      return i18n.translate('days_ago').replaceAll('{count}', '${difference.inDays}');
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return i18n.translate('months_ago').replaceAll('{count}', '$months');
    } else {
      final years = (difference.inDays / 365).floor();
      return i18n.translate('years_ago').replaceAll('{count}', '$years');
    }
  }

  /// Formata data completa (ex: "15 de Janeiro de 2024")
  static String formatFullDate(DateTime date, {required BuildContext context}) {
    final i18n = AppLocalizations.of(context);
    
    final day = date.day;
    final month = _getMonthName(date.month, i18n);
    final year = date.year;

    return '$day de $month de $year';
  }

  static String _getMonthName(int month, AppLocalizations i18n) {
    const months = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    
    if (month < 1 || month > 12) return '';
    return i18n.translate(months[month - 1]);
  }
}
