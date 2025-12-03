import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/shared/widgets/animated_emoji.dart';

/// Container circular com emoji centralizado
class EmojiContainer extends StatelessWidget {
  const EmojiContainer({
    super.key,
    required this.emoji,
    this.size = 80,
    this.emojiSize = 40,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  final String emoji;
  final double size;
  final double emojiSize;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? GlimpseColors.lightTextField,
        borderRadius: BorderRadius.circular(size / 2),
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? Colors.white,
                width: borderWidth,
              )
            : null,
      ),
      child: Center(
        child: AnimatedEmoji(
          emoji: emoji,
          size: emojiSize,
        ),
      ),
    );
  }
}
