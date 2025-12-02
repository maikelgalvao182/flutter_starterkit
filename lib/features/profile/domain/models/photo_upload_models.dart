/// Modelos para sistema de upload de fotos
/// Baseado no sistema do Advanced-Dating

/// Tipos de upload de foto
enum PhotoUploadType {
  profilePicture,
  galleryImage,
  video,
}

/// Dados para upload de foto
class PhotoUploadData {
  final String localPath;
  final String oldPhotoUrl;
  final PhotoUploadType uploadType;
  
  const PhotoUploadData({
    required this.localPath,
    required this.oldPhotoUrl,
    required this.uploadType,
  });
  
  @override
  String toString() {
    return 'PhotoUploadData(localPath: $localPath, uploadType: $uploadType)';
  }
}

/// Resultado de upload de foto
sealed class PhotoUploadResult {
  const PhotoUploadResult();
}

class PhotoUploadResultSuccess extends PhotoUploadResult {
  final String photoUrl;
  
  const PhotoUploadResultSuccess({required this.photoUrl});
}

class PhotoUploadResultFailure extends PhotoUploadResult {
  final String messageKey;
  final String? errorDetails;
  
  const PhotoUploadResultFailure({
    required this.messageKey,
    this.errorDetails,
  });
}