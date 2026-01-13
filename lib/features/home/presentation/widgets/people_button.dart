import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/models/user.dart' as app_user;
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/features/home/data/services/people_map_discovery_service.dart';
import 'package:partiu/shared/widgets/stable_avatar.dart';

/// Botão flutuante "Perto de você" com avatares empilhados
class PeopleButton extends StatefulWidget {
  const PeopleButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  State<PeopleButton> createState() => _PeopleButtonState();
}

class _PeopleButtonState extends State<PeopleButton> {
  final PeopleMapDiscoveryService _peopleCountService = PeopleMapDiscoveryService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: _peopleCountService.isViewportActive,
      builder: (context, viewportActive, _) {
        // Quando o zoom está muito afastado, o botão deve ficar inativo
        if (!viewportActive) {
          final full = i18n.translate('zoom_in_to_see_people').trim();
          String line1 = full;
          String line2 = '';

          // Preferir quebra determinística (pt): "Aumente o mapa" / "para ver pessoas"
          final splitToken = ' para ';
          final splitIdx = full.indexOf(splitToken);
          if (splitIdx > 0) {
            line1 = full.substring(0, splitIdx).trimRight();
            line2 = full.substring(splitIdx + 1).trimLeft(); // mantém "para ..."
          }

          return Material(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 48,
              padding: const EdgeInsets.only(left: 4, right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: GlimpseColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Iconsax.search_normal,
                      size: 20,
                      color: GlimpseColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.getFont(
                            FONT_PLUS_JAKARTA_SANS,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: GlimpseColors.primaryColorLight,
                          ),
                        ),
                        if (line2.isNotEmpty)
                          Text(
                            line2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.getFont(
                              FONT_PLUS_JAKARTA_SANS,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: GlimpseColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: GlimpseColors.primaryColorLight,
                  ),
                ],
              ),
            ),
          );
        }

        return ValueListenableBuilder<int>(
          valueListenable: _peopleCountService.nearbyPeopleCount,
          builder: (context, boundsCount, __) {
            return ValueListenableBuilder<List<app_user.User>>(
              valueListenable: _peopleCountService.nearbyPeople,
              builder: (context, nearbyPeople, ___) {
                final count = boundsCount.clamp(0, 1 << 30);

                final peopleNearYouLabel = i18n.translate('people_near_you');
                final countTemplate = count == 1
                    ? i18n.translate('nearby_people_count_singular')
                    : i18n.translate('nearby_people_count_plural');
                final peopleCountLabel = countTemplate.replaceAll('{count}', count.toString());

                final user = nearbyPeople.isNotEmpty ? nearbyPeople.first : null;
        
        // Se não tiver ninguém ou estiver carregando, mostra estado vazio ou loading?
        // O design original mostrava avatar se tivesse users.
        // Vamos mostrar o avatar do user mais recente se existir.

            return Material(
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(100),
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.only(left: 4, right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar único (do usuário mais recente)
                      if (user != null)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: StableAvatar(
                            userId: user.userId,
                            photoUrl: user.photoUrl,
                            size: 40,
                            enableNavigation: false,
                          ),
                        )
                      else
                        // Placeholder se não tiver user (opcional, ou manter vazio)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(Icons.person, color: Colors.grey[400], size: 20),
                        ),

                      const SizedBox(width: 8),

                      // Textos
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Texto "Perto de você"
                          Text(
                            peopleNearYouLabel,
                            style: GoogleFonts.getFont(
                              FONT_PLUS_JAKARTA_SANS,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: GlimpseColors.primaryColorLight,
                            ),
                          ),
                          // Contagem (baseada no bounding box do mapa)
                          Text(
                            peopleCountLabel,
                            style: GoogleFonts.getFont(
                              FONT_PLUS_JAKARTA_SANS,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: GlimpseColors.primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 4),

                      // Ícone chevron
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: GlimpseColors.primaryColorLight,
                      ),
                    ],
                  ),
                ),
              ),
            );
              },
            );
          },
        );
      },
    );
  }
}
