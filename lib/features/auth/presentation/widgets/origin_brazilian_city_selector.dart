import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brazilian_locations/brazilian_locations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';

/// Widget de seleção de Cidade e Estado (Brasil)
/// Usa brazilian_locations para lista de estados e cidades
class OriginBrazilianCitySelector extends StatefulWidget {
  const OriginBrazilianCitySelector({
    required this.initialValue,
    required this.onChanged,
    super.key,
  });

  final String? initialValue;
  final ValueChanged<String?> onChanged;

  @override
  State<OriginBrazilianCitySelector> createState() => _OriginBrazilianCitySelectorState();
}

class _OriginBrazilianCitySelectorState extends State<OriginBrazilianCitySelector> {
  String? _selectedState;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _parseInitialValue();
  }

  void _parseInitialValue() {
    if (widget.initialValue != null && widget.initialValue!.contains(' - ')) {
      final parts = widget.initialValue!.split(' - ');
      if (parts.length >= 2) {
        _selectedCity = parts[0];
        _selectedState = parts[1];
      }
    }
  }

  void _updateValue() {
    if (_selectedCity != null && _selectedState != null) {
      widget.onChanged('$_selectedCity - $_selectedState');
    } else {
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Cidade e Estado',
            style: GlimpseStyles.fieldLabelStyle(
              color: GlimpseColors.primaryColorLight,
            ),
          ),
        ),
        
        // BrazilianLocations Widget
        BrazilianLocations(
          currentState: _selectedState ?? 'Estado',
          currentCity: _selectedCity ?? 'Cidade',
          showStates: true,
          showCities: true,
          showDropdownLabel: false, // Oculta labels internos pois já temos o nosso
          stateSearchPlaceholder: 'Buscar Estado',
          citySearchPlaceholder: 'Buscar Cidade',
          stateDropdownLabel: 'Selecione o Estado',
          cityDropdownLabel: 'Selecione a Cidade',
          dropdownDecoration: BoxDecoration(
            color: GlimpseColors.lightTextField,
            borderRadius: BorderRadius.circular(12),
          ),
          disabledDropdownDecoration: BoxDecoration(
            color: GlimpseColors.lightTextField.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          dropdownHeadingStyle: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: GlimpseColors.primaryColorLight,
          ),
          dropdownItemStyle: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 14,
            color: GlimpseColors.textSubTitle,
          ),
          selectedItemStyle: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 14,
            color: GlimpseColors.primary,
            fontWeight: FontWeight.w600,
          ),
          onStateChanged: (state) {
            setState(() {
              _selectedState = state;
              _selectedCity = null; // Reseta cidade ao mudar estado
            });
            _updateValue();
          },
          onCityChanged: (city) {
            setState(() {
              _selectedCity = city;
            });
            _updateValue();
          },
        ),
      ],
    );
  }
}
