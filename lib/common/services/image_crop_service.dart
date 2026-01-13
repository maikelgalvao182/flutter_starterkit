import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/core/utils/app_logger.dart';

/// Serviço para corte de imagens
class ImageCropService {
  static const String _tag = 'ImageCropService';

  // Proteção global contra execuções concorrentes do crop.
  // Ajuda a evitar crash do plugin no Android (Reply already submitted).
  static bool _cropInProgress = false;

  /// Corta a imagem em formato quadrado
  Future<File?> cropToSquare(File imageFile) async {
    return cropImage(imageFile, isCircle: true);
  }

  /// Corta a imagem selecionada
  Future<File?> cropImage(File imageFile, {bool isCircle = true}) async {
    try {
      if (_cropInProgress) {
        AppLogger.warning(
          'Crop já está em andamento; ignorando nova solicitação',
          tag: _tag,
        );
        return null;
      }

      _cropInProgress = true;

      final i18n = await AppLocalizations.loadForLanguageCode(
        AppLocalizations.currentLocale,
      );
      final title = i18n.translate('image_crop_edit_photo_title').isNotEmpty
          ? i18n.translate('image_crop_edit_photo_title')
          : 'Editar Foto';

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: isCircle
            ? const CropAspectRatio(ratioX: 1, ratioY: 1)
            : const CropAspectRatio(ratioX: 4, ratioY: 3),
        compressQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.blue,
            cropStyle: isCircle ? CropStyle.circle : CropStyle.rectangle,
            initAspectRatio: isCircle
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.original,
            aspectRatioPresets: isCircle
                ? const [CropAspectRatioPreset.square]
                : const [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.ratio4x3,
                  ],
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: title,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            cropStyle: isCircle ? CropStyle.circle : CropStyle.rectangle,
          ),
        ],
      );

      if (croppedFile != null) {
        var output = File(croppedFile.path);
        if (isCircle) {
          output = await _ensureSquare(output);
        }
        return output;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao abrir/realizar crop: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      _cropInProgress = false;
    }
  }

  Future<File> _ensureSquare(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return file;
      }

      if (decoded.width == decoded.height) {
        return file;
      }

      final side = decoded.width < decoded.height ? decoded.width : decoded.height;
      final offsetX = ((decoded.width - side) / 2).round();
      final offsetY = ((decoded.height - side) / 2).round();

      final squared = img.copyCrop(
        decoded,
        x: offsetX,
        y: offsetY,
        width: side,
        height: side,
      );

      await file.writeAsBytes(
        img.encodeJpg(squared, quality: 90),
        flush: true,
      );
      return file;
    } catch (_) {
      return file;
    }
  }

  /// Corta a imagem com opções customizadas
  Future<File?> cropImageWithOptions({
    required File imageFile,
    CropStyle cropStyle = CropStyle.circle,
    double ratioX = 1.0,
    double ratioY = 1.0,
    int maxWidth = 1080,
    int maxHeight = 1080,
    int compressQuality = 85,
  }) async {
    try {
      if (_cropInProgress) {
        AppLogger.warning(
          'Crop já está em andamento; ignorando nova solicitação',
          tag: _tag,
        );
        return null;
      }

      _cropInProgress = true;

      final i18n = await AppLocalizations.loadForLanguageCode(
        AppLocalizations.currentLocale,
      );
      final title = i18n.translate('image_crop_edit_photo_title').isNotEmpty
          ? i18n.translate('image_crop_edit_photo_title')
          : 'Editar Foto';

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
        compressQuality: compressQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.blue,
            cropStyle: cropStyle,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: title,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            cropStyle: cropStyle,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao abrir/realizar crop (custom): $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      _cropInProgress = false;
    }
  }
}
