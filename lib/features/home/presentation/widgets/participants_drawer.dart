import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/home/presentation/widgets/participants/age_range_filter.dart';
import 'package:partiu/features/home/presentation/widgets/participants/privacy_type_selector.dart';
import 'package:partiu/shared/widgets/glimpse_back_button.dart';
import 'package:partiu/shared/widgets/glimpse_button.dart';
import 'package:partiu/shared/widgets/glimpse_close_button.dart';

/// Bottom sheet para seleção de participantes e privacidade da atividade
class ParticipantsDrawer extends StatefulWidget {
  const ParticipantsDrawer({super.key});

  @override
  State<ParticipantsDrawer> createState() => _ParticipantsDrawerState();
}

class _ParticipantsDrawerState extends State<ParticipantsDrawer> {
  double _minAge = 18;
  double _maxAge = 80;
  PrivacyType? _selectedPrivacyType;

  void _handleContinue() {
    if (_selectedPrivacyType == null) return;

    final result = {
      'minAge': _minAge.round(),
      'maxAge': _maxAge.round(),
      'privacyType': _selectedPrivacyType,
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle e header
              Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: GlimpseColors.borderColorLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Header: Back + Título + Close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botão voltar
                        GlimpseBackButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),

                        // Título centralizado
                        Expanded(
                          child: Text(
                            'Quem pode participar?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.getFont(
                              FONT_PLUS_JAKARTA_SANS,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: GlimpseColors.textSubTitle,
                            ),
                          ),
                        ),

                        // Botão fechar
                        const GlimpseCloseButton(
                          size: 32,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Filtro de idade
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AgeRangeFilter(
                  minAge: _minAge,
                  maxAge: _maxAge,
                  onRangeChanged: (RangeValues values) {
                    setState(() {
                      _minAge = values.start;
                      _maxAge = values.end;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Cards de seleção de privacidade
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PrivacyTypeSelector(
                  selectedType: _selectedPrivacyType,
                  onTypeSelected: (type) {
                    setState(() {
                      _selectedPrivacyType = type;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Botão de continuar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlimpseButton(
                  text: 'Continuar',
                  onPressed: _selectedPrivacyType != null ? _handleContinue : null,
                ),
              ),

              // Padding bottom para safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
