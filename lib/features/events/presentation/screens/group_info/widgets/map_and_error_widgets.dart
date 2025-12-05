import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Widget do mapa de localização do evento
class EventMapWidget extends StatelessWidget {
  const EventMapWidget({
    required this.locationText,
    required this.onOpenMaps,
    super.key,
  });

  final String locationText;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        color: GlimpseColors.bgColorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GlimpseColors.borderColorLight,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // TODO: Implementar mapa interativo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  IconsaxPlusBold.location,
                  size: 48,
                  color: GlimpseColors.primary,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    locationText,
                    style: GoogleFonts.getFont(
                      FONT_PLUS_JAKARTA_SANS,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: GlimpseColors.primaryColorLight,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: _OpenMapsButton(
              onTap: onOpenMaps,
              label: i18n.translate('open_in_maps'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão para abrir o mapa
class _OpenMapsButton extends StatelessWidget {
  const _OpenMapsButton({
    required this.onTap,
    required this.label,
  });

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GlimpseColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              IconsaxPlusLinear.export_1,
              size: 16,
              color: GlimpseColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de estado de erro
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    required this.errorMessage,
    required this.onRetry,
    super.key,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            IconsaxPlusBroken.info_circle,
            size: 64,
            color: GlimpseColors.textSubTitle,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 16,
                color: GlimpseColors.textSubTitle,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onRetry,
            child: Text(
              i18n.translate('try_again'),
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GlimpseColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
