import 'package:partiu/features/profile/presentation/widgets/user_images_grid.dart';
import 'package:flutter/material.dart';

class GalleryTab extends StatelessWidget {
  const GalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('=== [GalleryTab] 🏗️ BUILD CALLED ===');
    debugPrint('[GalleryTab] 🏗️ Building gallery tab with UserImagesGrid');
    debugPrint('[GalleryTab] 📋 Context: ${context.widget.runtimeType}');
    
    return const UserImagesGrid(
      key: ValueKey('gallery_images_grid'),
    );
  }
}
