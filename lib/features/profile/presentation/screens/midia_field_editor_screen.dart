import 'package:flutter/material.dart';
import 'package:partiu/features/profile/presentation/models/midia_field_type.dart';
import 'package:partiu/features/profile/presentation/tabs/gallery_tab.dart';

class MidiaFieldEditorScreen extends StatelessWidget {
  const MidiaFieldEditorScreen({
    super.key,
    required this.fieldType,
  });

  final MidiaFieldType fieldType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              fieldType.icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              fieldType.title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (fieldType) {
      case MidiaFieldType.gallery:
        return const GalleryTab();
      case MidiaFieldType.videos:
        return const Center(
          child: Text(
            'Vídeos em breve...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        );
    }
  }
}