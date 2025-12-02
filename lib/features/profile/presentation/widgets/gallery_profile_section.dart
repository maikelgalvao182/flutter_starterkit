import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Gallery section widget exibindo grid de imagens
/// 
/// - Espaçamento superior: 24px
/// - Espaçamento inferior: 36px  
/// - Padding horizontal: 20px
/// - Grid 3 colunas, aspect ratio 4:5
/// - Auto-oculta se galeria vazia
class GalleryProfileSection extends StatelessWidget {

  const GalleryProfileSection({
    required this.galleryMap, 
    super.key,
    this.title,
    this.titleColor,
    this.maxRows = 6,
    this.columns = 3,
    this.aspectRatio = 4 / 5,
  });
  
  final Map<String, dynamic>? galleryMap;
  final String? title;
  final Color? titleColor;
  final int maxRows;
  final int columns;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final effectiveTitleColor = titleColor ?? GlimpseColors.primaryColorLight;
    
    // ✅ AUTO-OCULTA: não renderiza seção vazia
    if (galleryMap == null || galleryMap!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Extrai URLs das imagens
    final imageUrls = _extractImageUrls(galleryMap!);
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    
    final maxItems = columns * maxRows;
    final limited = imageUrls.take(maxItems).toList();
    
    return Container(
      padding: GlimpseStyles.profileSectionPadding,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title ?? i18n.translate('gallery_section_title'),
            style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: effectiveTitleColor,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 16),
          
          // Grid
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: aspectRatio,
            ),
            itemCount: limited.length,
            itemBuilder: (context, index) {
              final imageUrl = limited[index];
              return _ImageThumb(
                key: ValueKey(imageUrl),
                imageUrl: imageUrl,
              );
            },
          ),
        ],
      ),
    );
  }
  
  List<String> _extractImageUrls(Map<String, dynamic> gallery) {
    final urls = <String>[];
    
    // Ordena pelas chaves numéricas
    final entries = gallery.entries.where((e) => e.value != null).toList();
    entries.sort((a, b) {
      int parseKey(String k) {
        final numPart = RegExp(r'(\d+)').firstMatch(k)?.group(1);
        return int.tryParse(numPart ?? k) ?? 0;
      }
      return parseKey(a.key).compareTo(parseKey(b.key));
    });
    
    for (final e in entries) {
      final val = e.value;
      final url = val is Map ? (val['url'] ?? '').toString() : val.toString();
      if (url.isNotEmpty) {
        urls.add(url);
      }
    }
    
    return urls;
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({
    required this.imageUrl,
    super.key,
  });
  
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: GlimpseColors.lightTextField,
            child: const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
                color: GlimpseColors.primaryColorLight,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: GlimpseColors.lightTextField,
            child: const Center(
              child: Icon(
                Icons.photo_outlined,
                color: Colors.white70,
                size: 28,
              ),
            ),
          ),
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
        ),
      ),
    );
  }
}
