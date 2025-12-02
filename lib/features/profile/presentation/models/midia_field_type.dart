/// Tipos de campos disponíveis na tab Mídia do EditProfile
enum MidiaFieldType {
  gallery,
  videos,
}

extension MidiaFieldTypeExtension on MidiaFieldType {
  /// Título do campo para exibição na UI
  String get title {
    switch (this) {
      case MidiaFieldType.gallery:
        return 'Galeria';
      case MidiaFieldType.videos:
        return 'Vídeos';
    }
  }

  /// Texto de adicionar quando o campo está vazio
  String get addText {
    switch (this) {
      case MidiaFieldType.gallery:
        return 'Adicionar fotos';
      case MidiaFieldType.videos:
        return 'Adicionar vídeos';
    }
  }

  /// Ícone do campo
  String get icon {
    switch (this) {
      case MidiaFieldType.gallery:
        return '📷';
      case MidiaFieldType.videos:
        return '🎥';
    }
  }
}