import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

/// Widget de filtro de idade com RangeSlider
class AgeRangeFilter extends StatelessWidget {
  const AgeRangeFilter({
    required this.minAge,
    required this.maxAge,
    required this.onRangeChanged,
    super.key,
  });

  final double minAge;
  final double maxAge;
  final ValueChanged<RangeValues> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlimpseColors.lightTextField,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone + Título
          Row(
            children: [
              Icon(
                IconsaxPlusLinear.cake,
                size: 24,
                color: GlimpseColors.primaryColorLight,
              ),
              const SizedBox(width: 12),
              Text(
                'Filtrar idade',
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: GlimpseColors.primaryColorLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Range Slider com labels customizados
          _AgeRangeSliderWithLabels(
            minAge: minAge,
            maxAge: maxAge,
            onRangeChanged: onRangeChanged,
          ),
        ],
      ),
    );
  }
}

/// Widget interno que gerencia o slider e os labels posicionados
class _AgeRangeSliderWithLabels extends StatelessWidget {
  const _AgeRangeSliderWithLabels({
    required this.minAge,
    required this.maxAge,
    required this.onRangeChanged,
  });

  final double minAge;
  final double maxAge;
  final ValueChanged<RangeValues> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcula a posição dos thumbs baseado nos valores
        const minValue = 18.0;
        const maxValue = 80.0;
        final range = maxValue - minValue;
        
        // O RangeSlider tem um padding interno de 24px de cada lado (overlay radius padrão)
        const sliderPadding = 24.0;
        final trackWidth = constraints.maxWidth - (sliderPadding * 2);
        
        // Posição relativa dos thumbs (0.0 a 1.0)
        final minPosition = (minAge - minValue) / range;
        final maxPosition = (maxAge - minValue) / range;
        
        // Posição absoluta do centro do thumb em pixels
        final minThumbCenter = sliderPadding + (trackWidth * minPosition);
        final maxThumbCenter = sliderPadding + (trackWidth * maxPosition);

        return Column(
          children: [
            // Range Slider
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: GlimpseColors.primary,
                inactiveTrackColor: GlimpseColors.borderColorLight,
                thumbColor: GlimpseColors.primary,
                overlayColor: Colors.transparent,
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 10,
                  elevation: 0,
                ),
                rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
              ),
              child: RangeSlider(
                values: RangeValues(minAge, maxAge),
                min: minValue,
                max: maxValue,
                divisions: 62,
                onChanged: onRangeChanged,
              ),
            ),

            const SizedBox(height: 8),

            // Labels posicionados sob os thumbs
            SizedBox(
              height: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Label mínimo - centralizado sob o thumb
                  Positioned(
                    left: minThumbCenter,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Text(
                        '${minAge.round()}',
                        style: GoogleFonts.getFont(
                          FONT_PLUS_JAKARTA_SANS,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: GlimpseColors.textSubTitle,
                        ),
                      ),
                    ),
                  ),
                  // Label máximo - centralizado sob o thumb
                  Positioned(
                    left: maxThumbCenter,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Text(
                        '${maxAge.round()}',
                        style: GoogleFonts.getFont(
                          FONT_PLUS_JAKARTA_SANS,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: GlimpseColors.textSubTitle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
