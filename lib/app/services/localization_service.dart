import 'package:flutter/material.dart';

/// Serviço de localização/internacionalização
/// Fornece traduções para a aplicação
class LocalizationService {
  static const Map<String, Map<String, String>> _translations = {
    'pt': {
      'profile': 'Perfil',
      'view_profile': 'Ver Perfil',
      'edit_profile': 'Editar Perfil',
      'profile_visits': 'Visitas',
      'language': 'Idioma',
      'likes': 'Curtidas',
      'blocked_users': 'Usuários Bloqueados',
      'about_us': 'Sobre Nós',
      'share_with_friends': 'Compartilhar com Amigos',
      'rate_on_play_store': 'Avaliar na Play Store',
      'rate_on_app_store': 'Avaliar na App Store',
      'privacy_policy': 'Política de Privacidade',
      'terms_of_service': 'Termos de Serviço',
      'sign_out': 'Sair',
      'delete_account': 'Excluir Conta',
      'distance_unit': 'Unidade de Distância',
      'from_label': 'Nasceu em',
      'CANCEL': 'CANCELAR',
      'DELETE': 'EXCLUIR',
      'all_your_profile_data_will_be_permanently_deleted': 'Todos os seus dados de perfil serão permanentemente excluídos',
    },
    'en': {
      'profile': 'Profile',
      'view_profile': 'View Profile',
      'edit_profile': 'Edit Profile',
      'profile_visits': 'Visits',
      'language': 'Language',
      'likes': 'Likes',
      'blocked_users': 'Blocked Users',
      'about_us': 'About Us',
      'share_with_friends': 'Share with Friends',
      'rate_on_play_store': 'Rate on Play Store',
      'rate_on_app_store': 'Rate on App Store',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'sign_out': 'Sign Out',
      'delete_account': 'Delete Account',
      'distance_unit': 'Distance Unit',
      'from_label': 'Born in',
      'CANCEL': 'CANCEL',
      'DELETE': 'DELETE',
      'all_your_profile_data_will_be_permanently_deleted': 'All your profile data will be permanently deleted',
    },
  };

  /// Obtém instância do serviço de localização
  static LocalizationService of(BuildContext context) {
    return LocalizationService();
  }

  /// Traduz uma chave para o idioma atual
  String? translate(String key) {
    // Por agora, sempre usa português
    const currentLanguage = 'pt';
    
    final languageTranslations = _translations[currentLanguage];
    return languageTranslations?[key];
  }

  /// Verifica se uma tradução existe
  bool hasTranslation(String key) {
    const currentLanguage = 'pt';
    return _translations[currentLanguage]?.containsKey(key) ?? false;
  }

  /// Obtém todas as traduções para um idioma
  Map<String, String> getTranslationsForLanguage(String languageCode) {
    return _translations[languageCode] ?? {};
  }
}