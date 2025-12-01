import 'package:partiu/common/state/app_state.dart';
// Firestore removido da UI: usar serviço
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/app/services/localization_service.dart';
import 'package:partiu/features/profile/data/services/vip_access_service.dart';
import 'package:partiu/features/profile/data/services/visits_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';

class ProfileVisitsChip extends StatelessWidget {
  const ProfileVisitsChip({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AppState.currentUserId ?? '';
    
    // Show skeleton if user not loaded yet
    if (userId.isEmpty) {
      return _buildSkeletonChip();
    }
    
    final visitsService = VisitsService.instance;

    return GestureDetector(
      onTap: () async {
        final hasAccess = await VipAccessService.checkAccessOrShowDialog(
          context, 
          source: 'ProfileVisitsChip',
        );
        if (hasAccess) {
          // TODO: Implementar navegação para tela de visitas
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => const ProfileVisitsScreenWrapper(),
          //   ),
          // );
        }
      },
      child: Container(
        height: 31,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: GlimpseColors.visitsChipBackground,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/svg/eye-show-pass.svg',
              height: 16,
              colorFilter: const ColorFilter.mode(
                GlimpseColors.visitsChipText,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Builder(
              builder: (context) {
                final i18n = LocalizationService.of(context);
                return Text(
                  i18n.translate('profile_visits') ?? 'Visitas',
                  style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                    color: GlimpseColors.visitsChipText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              }
            ),
            const SizedBox(width: 4),
            StreamBuilder<int>(
              stream: visitsService.watchUserVisitsCount(userId),
              initialData: visitsService.cachedVisitsCount,
              builder: (context, snapshot) {
                final visits = snapshot.data ?? 0;
                return Text(
                  visits.toString(),
                  style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                    color: GlimpseColors.visitsChipText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSkeletonChip() {
    return Container(
      width: 80,
      height: 31,
      decoration: BoxDecoration(
        color: GlimpseColors.lightTextField,
        borderRadius: BorderRadius.circular(15.5),
      ),
    );
  }
}