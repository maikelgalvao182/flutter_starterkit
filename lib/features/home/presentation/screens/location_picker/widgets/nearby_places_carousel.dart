import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/shared/screens/media_viewer_screen.dart';

/// Carousel horizontal com swipe de fotos do lugar selecionado
class SelectedPlacePhotosCarousel extends StatelessWidget {
  const SelectedPlacePhotosCarousel({
    super.key,
    required this.photoUrls,
    required this.placeName,
  });

  final List<String> photoUrls; // Agora recebe URLs reais
  final String placeName;

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: photoUrls.length,
        itemBuilder: (context, index) {
          final photoUrl = photoUrls[index]; // Usar URL diretamente

          return GestureDetector(
            onTap: () {
              // Abrir lightbox com todas as fotos
              final items = photoUrls.map((url) => MediaViewerItem(
                url: url,
                heroTag: 'place_photo_$url',
              )).toList();

              Navigator.of(context).push(
                PageRouteBuilder<void>(
                  pageBuilder: (context, animation, secondaryAnimation) => MediaViewerScreen(
                    items: items,
                    initialIndex: index,
                    disableHero: true,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => 
                    FadeTransition(opacity: animation, child: child),
                ),
              );
            },
            child: Container(
              width: 260, // Largura dobrada (120 * 2 + margem)
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CupertinoActivityIndicator(
                        radius: 12,
                        color: GlimpseColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.place,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
