import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/home/presentation/widgets/people_button_controller.dart';
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
  final _controller = NearbyButtonController();

  @override
  void initState() {
    super.initState();
    _controller.loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final user = _controller.recentUser;
        final count = _controller.nearbyCount;
        
        // Se não tiver ninguém ou estiver carregando, mostra estado vazio ou loading?
        // O design original mostrava avatar se tivesse users.
        // Vamos mostrar o avatar do user mais recente se existir.

        return Material(
          elevation: 4,
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
                        'Perto de você',
                        style: GoogleFonts.getFont(
                          FONT_PLUS_JAKARTA_SANS,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: GlimpseColors.primaryColorLight,
                        ),
                      ),
                      // Contagem
                      if (count > 0)
                        Text(
                          '$count pessoas',
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
  }
}
