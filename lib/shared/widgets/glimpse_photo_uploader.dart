import 'dart:async';
import 'dart:io';

import 'package:partiu/common/services/image_crop_service.dart';
import 'package:partiu/common/services/image_picker_service.dart';
import 'package:partiu/common/utils/app_logger.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:go_router/go_router.dart';

/// Componente para upload de foto de perfil estilo Glimpse
class GlimpsePhotoUploader extends StatefulWidget {

  const GlimpsePhotoUploader({
    required this.imageFile, required this.onImageSelected, super.key,
    this.size = 150,
    this.placeholder = '',
    this.customIcon,
  });
  final File? imageFile;
  final Function(File) onImageSelected;
  final double size;
  final String placeholder;
  final Widget? customIcon;

  @override
  State<GlimpsePhotoUploader> createState() => _GlimpsePhotoUploaderState();
}

class _GlimpsePhotoUploaderState extends State<GlimpsePhotoUploader> {
  bool _processing = false;
  final ImagePickerService _pickerService = ImagePickerService();
  final ImageCropService _cropService = ImageCropService();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _processing ? null : () => _showImageSourceDialog(context),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: GlimpseColors.lightTextField,
          shape: BoxShape.circle,
          border: Border.all(
            color: GlimpseColors.borderColorLight,
          ),
          image: widget.imageFile != null
              ? DecorationImage(
                  image: FileImage(widget.imageFile!),
                  fit: BoxFit.cover,
                )
              : const DecorationImage(
                  image: AssetImage('assets/images/empty_avatar.jpg'),
                  fit: BoxFit.cover,
                ),
        ),
        child: Stack(
          children: [
            if (widget.imageFile != null)
              Positioned(
                bottom: 0,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GlimpseColors.primaryColorLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: SvgPicture.asset(
                    'assets/svg/edit-2.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).translate('select_photo'),
                  style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: GlimpseColors.textColorLight,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      context,
                      icon: IconsaxPlusLinear.camera,
                      label: AppLocalizations.of(context).translate('camera'),
                      onTap: () async {
                        if (_processing) return;
                        context.pop();
                        await Future.delayed(const Duration(milliseconds: 80));
                        if (!mounted) return;
                        setState(() => _processing = true);
                        try {
                          await _getImageFromCamera();
                        } finally {
                          if (mounted) setState(() => _processing = false);
                        }
                      },
                    ),
                    _buildOptionButton(
                      context,
                      icon: IconsaxPlusLinear.gallery,
                      label: AppLocalizations.of(context).translate('gallery'),
                      onTap: () async {
                        if (_processing) return;
                        context.pop();
                        await Future.delayed(const Duration(milliseconds: 80));
                        if (!mounted) return;
                        setState(() => _processing = true);
                        try {
                          await _getImageFromGallery();
                        } finally {
                          if (mounted) setState(() => _processing = false);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
  onTap: _processing ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: GlimpseColors.lightTextField,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: GlimpseColors.primaryColorLight,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: GlimpseColors.textColorLight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getImageFromCamera() async {
    AppLogger.info('[GlimpsePhotoUploader] [GREEN] Starting camera image picker');
    try {
      final xfile = await _pickerService.pickImage(ImageSource.camera);
      if (xfile == null || !mounted) return;
      
      final file = File(xfile.path);
      await _cropAndSelectImage(file);
    } catch (e) {
      AppLogger.error('[GlimpsePhotoUploader] Error picking camera image: $e');
    }
  }

  Future<void> _getImageFromGallery() async {
    AppLogger.info('[GlimpsePhotoUploader] [GREEN] Starting gallery image picker');
    try {
      final xfile = await _pickerService.pickImage(ImageSource.gallery);
      if (xfile == null || !mounted) return;
      
      final file = File(xfile.path);
      await _cropAndSelectImage(file);
    } catch (e) {
      AppLogger.error('[GlimpsePhotoUploader] Error picking gallery image: $e');
    }
  }

  Future<void> _cropAndSelectImage(File imageFile) async {
    AppLogger.info('[GlimpsePhotoUploader] 🟡 Starting image cropper...');
    var processed = false;
    try {
      final cropped = await _cropService.cropToSquare(imageFile);
      processed = true;
      if (cropped != null) {
        widget.onImageSelected(cropped);
      } else {
      }
    } catch (e) {
      if (!processed) {
      }
    }
  }
}
