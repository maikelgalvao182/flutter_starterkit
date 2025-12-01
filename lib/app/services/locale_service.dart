import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço central de gerenciamento de idiomas
/// Responsável por:
/// - Armazenar e recuperar idioma selecionado
/// - Orquestrar mudanças de idioma em toda aplicação
/// - Gerenciar fallbacks de tradução
class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  
  // Idiomas suportados
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // Inglês
    Locale('pt', 'BR'), // Português
    Locale('es', 'ES'), // Espanhol
  ];

  // Locale atual (default: português)
  Locale _currentLocale = const Locale('pt', 'BR');

  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;

  /// Inicializa o serviço carregando o idioma salvo
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    
    if (savedLocale != null) {
      _currentLocale = _parseLocale(savedLocale);
    } else {
      // Usa português como padrão
      _currentLocale = const Locale('pt', 'BR');
    }
    
    debugPrint('🌍 LocaleService initialized: ${_currentLocale.languageCode}');
  }

  /// Muda o idioma da aplicação
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      debugPrint('⚠️ Locale ${locale.languageCode} not supported');
      return;
    }

    _currentLocale = locale;
    
    // Salva no SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.toString());
    
    // Notifica mudança
    notifyListeners();
    
    debugPrint('🌍 Locale changed to: ${locale.languageCode}');
  }

  /// Converte string para Locale
  Locale _parseLocale(String localeString) {
    final parts = localeString.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }



  /// Verifica se um locale é suportado
  bool isSupported(Locale locale) {
    return supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  /// Obtém nome do idioma para exibição
  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return locale.languageCode.toUpperCase();
    }
  }
}