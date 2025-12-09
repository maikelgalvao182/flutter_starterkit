import 'package:flutter/material.dart';

/// Controller para gerenciar o estado do CreateDrawer
class CreateDrawerController extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  
  String _currentEmoji = '🎉';
  bool _isSuggestionMode = false;
  bool _isUpdatingFromSuggestion = false;
  String? _lockedEmojiForText; // Emoji bloqueado para um texto específico

  String get currentEmoji => _currentEmoji;
  bool get isSuggestionMode => _isSuggestionMode;
  bool get isUpdatingFromSuggestion => _isUpdatingFromSuggestion;
  bool get canContinue => textController.text.trim().isNotEmpty;

  CreateDrawerController() {
    textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    notifyListeners();
  }

  void setEmoji(String emoji) {
    if (_currentEmoji != emoji) {
      _currentEmoji = emoji;
      notifyListeners();
    }
  }

  void toggleSuggestionMode() {
    _isSuggestionMode = !_isSuggestionMode;
    notifyListeners();
  }

  void setIsUpdatingFromSuggestion(bool value) {
    _isUpdatingFromSuggestion = value;
  }

  /// Define sugestão selecionada e bloqueia o emoji para aquele texto
  /// O emoji só será desbloqueado se o usuário modificar o texto
  void setSuggestion(String text, String emoji) {
    _isUpdatingFromSuggestion = true;
    textController.text = text;
    _currentEmoji = emoji;
    _lockedEmojiForText = text; // Bloqueia o emoji para este texto exato
    _isSuggestionMode = false;
    notifyListeners();
    
    // Usar Future.microtask para garantir que o listener seja executado
    // ANTES de resetar a flag
    Future.microtask(() {
      _isUpdatingFromSuggestion = false;
    });
  }
  
  /// Verifica se o emoji está bloqueado para o texto atual
  /// Retorna true se o emoji não deve ser alterado pelo helper
  bool isEmojiLockedForCurrentText() {
    if (_lockedEmojiForText == null) return false;
    return textController.text.trim() == _lockedEmojiForText!.trim();
  }
  
  /// Desbloqueia o emoji (chamado quando usuário edita manualmente)
  void unlockEmoji() {
    _lockedEmojiForText = null;
  }

  void clear() {
    textController.clear();
    _currentEmoji = '🎉';
    _isSuggestionMode = false;
    _isUpdatingFromSuggestion = false;
    _lockedEmojiForText = null; // Limpar lock ao resetar
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
