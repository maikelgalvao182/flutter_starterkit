import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:partiu/core/constants/constants.dart';

class GlimpseActionMenuItem {
  GlimpseActionMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
    this.isPrimary = false,
    this.isDisabled = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isPrimary;
  final bool isDisabled;
}

class GlimpseActionMenuButton extends StatelessWidget {

  const GlimpseActionMenuButton({
    required this.items, super.key,
    this.iconSize = 20,
    this.iconColor,
    this.buttonSize = 32,
    this.padding,
    this.buttonShape,
    this.backgroundColor,
  });
  final List<GlimpseActionMenuItem> items;
  final double iconSize;
  final Color? iconColor;
  final double buttonSize;
  final EdgeInsets? padding;
  final ShapeBorder? buttonShape;
  final Color? backgroundColor;

  void _openMenu(BuildContext context) {
    
    if (items.isEmpty) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'menu',
  barrierColor: Colors.black.withValues(alpha: 0.4),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: curved,
          child: Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
              child: _MenuPanel(items: items),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(buttonSize / 2),
          onTap: () => _openMenu(context),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Icon(Iconsax.more, size: iconSize, color: iconColor ?? Theme.of(context).iconTheme.color ?? Colors.black),
          ),
        ),
      ),
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({required this.items});
  final List<GlimpseActionMenuItem> items;

  static const _panelRadius = BorderRadius.all(Radius.circular(20));
  static const _dividerColorAlpha = 0.6;
  static const _panelShadow = BoxShadow(
    color: Color(0x26000000), // 15% alpha black
    blurRadius: 20,
    offset: Offset(0, 8),
  );

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: _panelRadius,
            border: Border.all(color: GlimpseColors.borderColorLight),
            boxShadow: const [_panelShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _MenuItemWidget(item: items[i]),
                if (i < items.length - 1)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    height: 1,
                    color: GlimpseColors.borderColorLight.withValues(alpha: _dividerColorAlpha),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemWidget extends StatelessWidget {
  const _MenuItemWidget({required this.item});
  final GlimpseActionMenuItem item;
  static const _itemRadiusMedium = BorderRadius.all(Radius.circular(12));
  static const _iconRadiusSmall = BorderRadius.all(Radius.circular(10));
  @override
  Widget build(BuildContext context) {
    final color = item.isDestructive
        ? Colors.red
        : item.isPrimary
            ? GlimpseColors.primaryColorLight
            : Theme.of(context).textTheme.titleMedium?.color ?? Colors.black87;
    final effectiveColor = item.isDisabled ? (Theme.of(context).disabledColor) : color;
    return InkWell(
      borderRadius: _itemRadiusMedium,
      onTap: item.isDisabled ? null : () { 
        Navigator.of(context).pop(); 
        item.onTap(); 
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (item.isDisabled ? effectiveColor.withValues(alpha: 0.05) : effectiveColor.withValues(alpha: 0.08)),
                borderRadius: _iconRadiusSmall,
              ),
              child: Icon(item.icon, size: 20, color: effectiveColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}