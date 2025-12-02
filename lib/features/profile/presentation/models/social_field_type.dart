/// Tipos de campos disponíveis na tab Social do EditProfile
enum SocialFieldType {
  website,
  instagram,
  tiktok,
  pinterest,
  youtube,
  vimeo,
}

extension SocialFieldTypeExtension on SocialFieldType {
  /// Título do campo para exibição na UI
  String get title {
    switch (this) {
      case SocialFieldType.website:
        return 'Website';
      case SocialFieldType.instagram:
        return 'Instagram';
      case SocialFieldType.tiktok:
        return 'TikTok';
      case SocialFieldType.pinterest:
        return 'Pinterest';
      case SocialFieldType.youtube:
        return 'YouTube';
      case SocialFieldType.vimeo:
        return 'Vimeo';
    }
  }

  /// Placeholder/hint do campo
  String get placeholder {
    switch (this) {
      case SocialFieldType.website:
        return 'https://seusite.com.br';
      case SocialFieldType.instagram:
        return '@seuusuario';
      case SocialFieldType.tiktok:
        return '@seuusuario';
      case SocialFieldType.pinterest:
        return '@seuusuario';
      case SocialFieldType.youtube:
        return 'Canal do YouTube';
      case SocialFieldType.vimeo:
        return 'Perfil do Vimeo';
    }
  }

  /// Texto de adicionar quando o campo está vazio
  String get addText {
    switch (this) {
      case SocialFieldType.website:
        return 'Adicionar website';
      case SocialFieldType.instagram:
        return 'Adicionar Instagram';
      case SocialFieldType.tiktok:
        return 'Adicionar TikTok';
      case SocialFieldType.pinterest:
        return 'Adicionar Pinterest';
      case SocialFieldType.youtube:
        return 'Adicionar YouTube';
      case SocialFieldType.vimeo:
        return 'Adicionar Vimeo';
    }
  }

  /// Ícone do campo
  String get icon {
    switch (this) {
      case SocialFieldType.website:
        return '🌐';
      case SocialFieldType.instagram:
        return '📸';
      case SocialFieldType.tiktok:
        return '🎵';
      case SocialFieldType.pinterest:
        return '📌';
      case SocialFieldType.youtube:
        return '🎥';
      case SocialFieldType.vimeo:
        return '📹';
    }
  }
}