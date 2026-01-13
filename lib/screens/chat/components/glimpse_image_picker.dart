import 'dart:io';

import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partiu/core/constants/constants.dart';

/// Componente para seleção de imagens estilo Glimpse
class GlimpseImagePicker extends StatelessWidget {

  static bool _cropInProgress = false;

  const GlimpseImagePicker({
    required this.onImageSelected, super.key,
  });
  final Function(File?) onImageSelected;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                i18n.translate('select_image'),
                style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    context,
                    icon: Iconsax.camera,
                    label: i18n.translate('camera'),
                    onTap: () {
                      Navigator.pop(context);
                      _getImage(context, ImageSource.camera);
                    },
                  ),
                  _buildOptionButton(
                    context,
                    icon: Iconsax.gallery,
                    label: i18n.translate('gallery'),
                    onTap: () {
                      Navigator.pop(context);
                      _getImage(context, ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: GlimpseColors.lightTextField,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getImage(BuildContext context, ImageSource source) async {
    // Captura todas as variáveis necessárias do contexto antes de qualquer operação assíncrona
    final i18n = AppLocalizations.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    final editCropImageText = i18n.translate('edit_crop_image');
    
    // Usa um try-catch para evitar erros se o widget for desativado
    try {
      if (_cropInProgress) {
        return;
      }

      _cropInProgress = true;

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        // Crop a imagem
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          maxWidth: 800,
          maxHeight: 800,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: editCropImageText,
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: editCropImageText,
            ),
          ],
        );

        // Verifica se o widget ainda está montado antes de chamar o callback
        // Verifica se a imagem foi cortada
        if (croppedFile != null) {
          onImageSelected(File(croppedFile.path));
        } else {
          // Se o usuário cancelou o corte, usa a imagem original
          onImageSelected(File(pickedFile.path));
        }
      }
    } catch (e) {
      // Ignore image picking/cropping errors
    } finally {
      _cropInProgress = false;
    }
  }
}
