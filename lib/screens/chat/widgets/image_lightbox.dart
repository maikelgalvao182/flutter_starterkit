import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ImageLightbox extends StatelessWidget {

  const ImageLightbox({required this.imageUrl, super.key, this.heroTag});
  final String imageUrl;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Fullscreen zoomable image
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: Center(
                        child: CupertinoActivityIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, color: Colors.white54, size: 96);
                  },
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
