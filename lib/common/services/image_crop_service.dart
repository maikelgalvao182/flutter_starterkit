import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

/// Serviço para corte de imagens
class ImageCropService {
  /// Corta a imagem em formato quadrado
  Future<File?> cropToSquare(File imageFile) async {
    return cropImage(imageFile, isCircle: true);
  }

  /// Corta a imagem selecionada
  Future<File?> cropImage(File imageFile, {bool isCircle = true}) async {
    try {
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
            toolbarTitle: 'Editar Foto',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.blue,
            cropStyle: isCircle ? CropStyle.circle : CropStyle.rectangle,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Editar Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            cropStyle: isCircle ? CropStyle.circle : CropStyle.rectangle,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      return null;
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
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
        compressQuality: compressQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Editar Foto',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.blue,
            cropStyle: cropStyle,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Editar Foto',
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
    } catch (e) {
      return null;
    }
  }
}
