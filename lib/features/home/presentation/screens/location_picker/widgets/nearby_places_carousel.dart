import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

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

    // Importante: fotos de lugares (Google Places) não devem ser baixadas.
    // Mantemos o layout com placeholders locais para evitar qualquer request.
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: photoUrls.length,
        itemBuilder: (context, index) {
          return Container(
            width: 260,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.place,
                color: GlimpseColors.primary,
                size: 48,
              ),
            ),
          );
        },
      ),
    );
  }
}
