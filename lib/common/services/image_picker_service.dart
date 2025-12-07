import 'package:image_picker/image_picker.dart';

/// Serviço para seleção de imagens
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Seleciona imagem da galeria
  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (e) {
      return null;
    }
  }

  /// Seleciona imagem da câmera
  Future<XFile?> pickImageFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
    } catch (e) {
      return null;
    }
  }

  /// Seleciona imagem de uma fonte específica
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(
        source: source,
        imageQuality: 85,
        requestFullMetadata: false,
      );
    } catch (e) {
      return null;
    }
  }
}
