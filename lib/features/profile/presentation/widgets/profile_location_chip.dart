import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:partiu/core/constants/constants.dart';

class ProfileLocationChip extends StatelessWidget {
  const ProfileLocationChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: AppState.currentUser,
      builder: (context, user, _) {
        // Show skeleton if user not loaded yet
        if (user == null) {
          return _buildSkeletonChip();
        }
        
        final city = user.userLocality;
        final state = user.userState;

        // Se ambos estão vazios, não mostra nada (ou skeleton se estiver carregando?)
        // Assumindo que se user != null, já carregou.
        if (city.isEmpty && (state == null || state.isEmpty)) {
           // Se não tem localização, retorna vazio
           return const SizedBox.shrink();
        }
        
        // Constrói o texto da localização
        final locationText = city.isNotEmpty
            ? ((state ?? '').isNotEmpty ? "$city, ${state ?? ''}" : city)
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
          const Icon(
            Iconsax.location,
            size: 16,
            color: Colors.black,
          ),
          const SizedBox(width: 5),
          Text(
            locationText,
            style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
