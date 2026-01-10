import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partiu/features/profile/domain/models/photo_upload_models.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Serviço responsável por abstrair lógica de seleção e processamento de imagens
/// 
/// Responsabilidades:
/// - Solicitar permissões necessárias
/// - Abrir galeria/câmera para seleção de imagem
/// - Realizar crop da imagem selecionada
/// - Retornar PhotoUploadData pronto para upload
/// 
/// Segue boas práticas:
/// - Separação de preocupações (UI não lida com ImagePicker)
/// - Reutilizável em múltiplas telas
/// - Testável independentemente
/// - Encapsula dependências externas (ImagePicker, ImageCropper)
class ImagePickerService {
  static const String _tag = 'ImagePickerService';
  
  ImagePickerService({ImagePicker? picker}) 
      : _picker = picker ?? ImagePicker();
  
  final ImagePicker _picker;
  
  /// Seleciona imagem da galeria e faz crop
  /// 
  /// Retorna [PhotoUploadData] se sucesso, null se cancelado
  Future<PhotoUploadData?> pickAndCropImage({
    required String oldPhotoUrl,
    required PhotoUploadType uploadType,
    ImageSource source = ImageSource.gallery,
    int imageQuality = 80,
    CropAspectRatio aspectRatio = const CropAspectRatio(ratioX: 1, ratioY: 1),
  }) async {
    AppLogger.info('Starting image selection...', tag: _tag);
    
    try {
      // 1. Selecionar imagem
      final image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );
      
      if (image == null) {
        AppLogger.info('User cancelled image selection', tag: _tag);
        return null;
      }
      
      AppLogger.info('Image selected: ${image.path}', tag: _tag);
      
      // 2. Crop da imagem
      final croppedFile = await _cropImage(
        sourcePath: image.path,
        aspectRatio: aspectRatio,
      );
      
      if (croppedFile == null) {
        AppLogger.info('User cancelled image crop', tag: _tag);
        return null;
      }
      
      AppLogger.info('Image cropped: ${croppedFile.path}', tag: _tag);
      
      // 3. Validar arquivo
      final file = File(croppedFile.path);
      if (!await file.exists()) {
        AppLogger.error('Cropped file does not exist', tag: _tag);
        return null;
      }
      
      // 4. Retornar PhotoUploadData
      final photoData = PhotoUploadData(
        localPath: croppedFile.path,
        oldPhotoUrl: oldPhotoUrl,
        uploadType: uploadType,
      );
      
      AppLogger.info('PhotoUploadData created successfully', tag: _tag);
      return photoData;
      
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error in pickAndCropImage: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Realiza crop da imagem com configurações específicas por plataforma
  Future<CroppedFile?> _cropImage({
    required String sourcePath,
    required CropAspectRatio aspectRatio,
  }) async {
    AppLogger.info('Starting image crop...', tag: _tag);
    
    try {
      final i18n = await AppLocalizations.loadForLanguageCode(
        AppLocalizations.currentLocale,
      );
      final title = i18n.translate('image_crop_crop_image_title').isNotEmpty
          ? i18n.translate('image_crop_crop_image_title')
          : 'Recortar Imagem';

      final result = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: aspectRatio,
        compressQuality: 80,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: const Color(0xFF6C63FF), // Primary color
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: title,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
      
      if (result != null) {
        AppLogger.info('Image crop successful', tag: _tag);
      } else {
        AppLogger.info('Image crop cancelled by user', tag: _tag);
      }
      
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error cropping image: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Seleciona múltiplas imagens da galeria
  /// Útil para upload de fotos de portfólio/galeria
  Future<List<XFile>> pickMultipleImages({
    int imageQuality = 80,
    int? maxImages,
  }) async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
      );
      
      if (maxImages != null && images.length > maxImages) {
        return images.sublist(0, maxImages);
      }
      
      AppLogger.info('Selected ${images.length} images', tag: _tag);
      return images;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error picking multiple images: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
  
  /// Captura foto da câmera e faz crop
  Future<PhotoUploadData?> captureAndCropPhoto({
    required String oldPhotoUrl,
    required PhotoUploadType uploadType,
    int imageQuality = 80,
  }) async {
    return pickAndCropImage(
      oldPhotoUrl: oldPhotoUrl,
      uploadType: uploadType,
      source: ImageSource.camera,
      imageQuality: imageQuality,
    );
  }
}