import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/glimpse_styles.dart';

/// AppBar reutilizável para as tabs principais do app
/// Usado em: Profile, Conversations, Ranking, Matches
class GlimpseTabAppBar extends StatelessWidget {
  const GlimpseTabAppBar({
    required this.title,
    super.key,
    this.actions,
  });

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GlimpseStyles.messagesTitleStyle().copyWith(
                color: GlimpseColors.primaryColorLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// Botão de ação otimizado para usar no AppBar
class GlimpseTabActionButton extends StatelessWidget {
  const GlimpseTabActionButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          icon,
          size: 24,
          color: GlimpseColors.primaryColorLight,
        ),
        tooltip: tooltip,
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
      ),
    );
  }
}
