import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/shared/stores/hybrid_profile_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';

class ProfileLocationChip extends StatelessWidget {
  const ProfileLocationChip({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AppState.currentUserId ?? '';
    
    // Show skeleton if user not loaded yet
    if (userId.isEmpty) {
      return _buildSkeletonChip();
    }
    
    return ValueListenableBuilder<String?>(
      valueListenable: HybridProfileStore.instance.getCityNotifier(userId),
      builder: (context, city, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: HybridProfileStore.instance.getStateNotifier(userId),
          builder: (context, state, _) {
            // Se ambos estão vazios, mostra skeleton enquanto carrega
            if ((city == null || city.isEmpty) && (state == null || state.isEmpty)) {
              return _buildSkeletonChip();
            }
            
            // Constrói o texto da localização
            final locationText = (city ?? '').isNotEmpty
                ? ((state ?? '').isNotEmpty ? "${city ?? ''}, ${state ?? ''}" : city ?? '')
                : ((state ?? '').isNotEmpty ? state ?? '' : '');
            
            if (kDebugMode) {
              print('📍 [ProfileLocationChip] Building chip');
              print('   City: "$city"');
              print('   State: "$state"');
              print('   Final text: "$locationText"');
            }
            
            return _buildChip(locationText);
          },
        );
      },
    );
  }

  Widget _buildSkeletonChip() {
    return Container(
      width: 120,
      height: 28,
      decoration: BoxDecoration(
        color: GlimpseColors.lightTextField,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _buildChip(String locationText) {
    if (locationText.isEmpty) {
      return const SizedBox.shrink(); // Não mostra chip se não tem localização
    }
    
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: GlimpseColors.locationChipBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/svg/locationIcon.svg',
            height: 16,
            colorFilter: const ColorFilter.mode(
              GlimpseColors.locationChipText,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            locationText,
            style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
              color: GlimpseColors.locationChipText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}