import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/shared/widgets/glimpse_close_button.dart';
import 'package:partiu/shared/widgets/glimpse_dropdown.dart';
import 'package:partiu/shared/widgets/glimpse_button.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Advanced Filters Screen (filtros avançados para descoberta de atividades)
class AdvancedFiltersScreen extends StatefulWidget {
  const AdvancedFiltersScreen({super.key});

  @override
  State<AdvancedFiltersScreen> createState() => _AdvancedFiltersScreenState();
}

class _AdvancedFiltersScreenState extends State<AdvancedFiltersScreen> {
  // Filtros
  String? _selectedGender = 'all';
  RangeValues _ageRange = const RangeValues(18, 35);
  double _maxDistance = 25;
  bool _isVerified = false;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(i18n),
      body: _buildBody(i18n),
      floatingActionButton: _buildApplyButton(i18n),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  AppBar _buildAppBar(AppLocalizations i18n) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Text(
        i18n.translate('advanced_filters'),
        style: GoogleFonts.getFont(
          FONT_PLUS_JAKARTA_SANS,
          fontWeight: FontWeight.w700,
          color: GlimpseColors.primaryColorLight,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GlimpseCloseButton(
            color: GlimpseColors.primaryColorLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(AppLocalizations i18n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDistanceFilter(i18n),
          const SizedBox(height: 20),
          
          _buildAgeFilter(i18n),
          const SizedBox(height: 20),
          
          _buildGenderFilter(i18n),
          const SizedBox(height: 20),
          
          _buildVerifiedFilter(i18n),
          
          const SizedBox(height: 100), // Espaço para o botão flutuante
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.getFont(
        FONT_PLUS_JAKARTA_SANS,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: GlimpseColors.primaryColorLight,
      ),
    );
  }

  Widget _buildDistanceFilter(AppLocalizations i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(i18n.translate('distance')),
        const SizedBox(height: 12),
        Text(
          '${i18n.translate('up_to')} ${_maxDistance.toInt()} km',
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 14,
            color: GlimpseColors.textSubTitle,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: GlimpseColors.primary,
            inactiveTrackColor: GlimpseColors.textSubTitle.withOpacity(0.2),
            thumbColor: GlimpseColors.primary,
            overlayColor: GlimpseColors.primary.withOpacity(0.2),
            valueIndicatorColor: GlimpseColors.primary,
          ),
          child: Slider(
            value: _maxDistance,
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: (value) => setState(() => _maxDistance = value),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeFilter(AppLocalizations i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(i18n.translate('age')),
        const SizedBox(height: 12),
        Text(
          '${i18n.translate('from')} ${_ageRange.start.toInt()} ${i18n.translate('to')} ${_ageRange.end.toInt()} ${i18n.translate('years')}',
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 14,
            color: GlimpseColors.textSubTitle,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: GlimpseColors.primary,
            inactiveTrackColor: GlimpseColors.textSubTitle.withOpacity(0.2),
            thumbColor: GlimpseColors.primary,
            overlayColor: GlimpseColors.primary.withOpacity(0.2),
            valueIndicatorColor: GlimpseColors.primary,
          ),
          child: RangeSlider(
            values: _ageRange,
            min: 18,
            max: 60,
            divisions: 42,
            onChanged: (values) => setState(() => _ageRange = values),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderFilter(AppLocalizations i18n) {
    return GlimpseDropdown(
      labelText: i18n.translate('gender'),
      hintText: i18n.translate('gender'),
      items: [
        GENDER_ALL,
        GENDER_MAN,
        GENDER_WOMAN,
      ],
      selectedValue: _getGenderDisplayValue(i18n),
      onChanged: (value) {
        setState(() {
          if (value == GENDER_ALL) {
            _selectedGender = 'all';
          } else if (value == GENDER_MAN) {
            _selectedGender = 'male';
          } else if (value == GENDER_WOMAN) {
            _selectedGender = 'female';
          }
        });
      },
    );
  }

  String? _getGenderDisplayValue(AppLocalizations i18n) {
    switch (_selectedGender) {
      case 'all':
        return GENDER_ALL;
      case 'male':
        return GENDER_MAN;
      case 'female':
        return GENDER_WOMAN;
      default:
        return null;
    }
  }

  Widget _buildVerifiedFilter(AppLocalizations i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(i18n.translate('other_filters')),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: GlimpseColors.lightTextField,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GlimpseColors.borderColorLight.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                i18n.translate('only_verified'),
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: GlimpseColors.primaryColorLight,
                ),
              ),
              CupertinoSwitch(
                value: _isVerified,
                activeColor: GlimpseColors.primary,
                onChanged: (value) => setState(() => _isVerified = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton(AppLocalizations i18n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GlimpseButton(
        text: i18n.translate('apply_filters'),
        height: 55,
        onTap: _applyFilters,
      ),
    );
  }

  void _applyFilters() {
    final filterParams = {
      'maxDistance': _maxDistance,
      'ageRange': {'start': _ageRange.start, 'end': _ageRange.end},
      'gender': _selectedGender,
      'isVerified': _isVerified,
    };
    
    Navigator.pop(context, filterParams);
  }
}
