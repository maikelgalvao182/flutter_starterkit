import 'package:flutter/material.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Badge que pode ser atribuído em uma review
class ReviewBadge {
  final String key;
  final String emoji;
  final String titleKey;
  final Color color;

  const ReviewBadge({
    required this.key,
    required this.emoji,
    required this.titleKey,
    required this.color,
  });

  String localizedTitle(AppLocalizations i18n) {
    final translated = i18n.translate(titleKey);
    return translated.isNotEmpty ? translated : titleKey;
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'emoji': emoji,
      'titleKey': titleKey,
    };
  }

  static ReviewBadge? fromKey(String key) {
    try {
      return availableBadges.firstWhere((b) => b.key == key);
    } catch (_) {
      return null;
    }
  }
}

/// Lista de badges disponíveis para atribuir
const List<ReviewBadge> availableBadges = [
  ReviewBadge(
    key: 'mega_simpatico',
    emoji: '😄',
    titleKey: 'review_badge_mega_simpatico',
    color: Color(0xFFFFEB3B), // Amarelo
  ),
  ReviewBadge(
    key: 'muito_engracado',
    emoji: '😂',
    titleKey: 'review_badge_muito_engracado',
    color: Color(0xFFFF9800), // Laranja
  ),
  ReviewBadge(
    key: 'muito_inteligente',
    emoji: '🧠',
    titleKey: 'review_badge_muito_inteligente',
    color: Color(0xFF9C27B0), // Roxo
  ),
  ReviewBadge(
    key: 'estilo_impecavel',
    emoji: '😍',
    titleKey: 'review_badge_estilo_impecavel',
    color: Color(0xFFE91E63), // Pink
  ),
  ReviewBadge(
    key: 'super_educado',
    emoji: '🤝',
    titleKey: 'review_badge_super_educado',
    color: Color(0xFF2196F3), // Azul
  ),
  ReviewBadge(
    key: 'anima_todo_mundo',
    emoji: '🎉',
    titleKey: 'review_badge_anima_todo_mundo',
    color: Color(0xFF4CAF50), // Verde
  ),
  ReviewBadge(
    key: 'super_gato',
    emoji: '🐱',
    titleKey: 'review_badge_super_gato',
    color: Color(0xFFFF5722), // Vermelho
  ),
  ReviewBadge(
    key: 'bom_de_papo',
    emoji: '💬',
    titleKey: 'review_badge_bom_de_papo',
    color: Color(0xFF00BCD4), // Cyan
  ),
  ReviewBadge(
    key: 'super_pontual',
    emoji: '⏰',
    titleKey: 'review_badge_super_pontual',
    color: Color(0xFF795548), // Marrom
  ),
];
