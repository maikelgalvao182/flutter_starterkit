import 'package:flutter/material.dart';
import 'package:partiu/app/services/locale_service.dart';

/// Diálogo para seleção de idioma
class LanguageSelectorDialog {
  
  /// Mostra o diálogo de seleção de idioma
  static void show(BuildContext context, LocaleService localeService) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Selecionar Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleService.supportedLocales.map((locale) {
            final languageName = localeService.getLanguageName(locale);
            final isSelected = localeService.currentLocale == locale;
            
            return ListTile(
              title: Text(languageName),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                localeService.setLocale(locale);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}