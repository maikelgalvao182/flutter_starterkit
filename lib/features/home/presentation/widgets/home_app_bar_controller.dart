import 'package:flutter/material.dart';

/// Controller simplificado para gerenciar o carregamento assíncrono dos dados do usuário na HomeAppBar
/// TODO: Integrar com sistema de autenticação e estado global quando disponível
class HomeAppBarController extends ChangeNotifier {
  HomeAppBarController() {
    _init();
  }

  final ValueNotifier<bool> isFullyLoadedNotifier = ValueNotifier<bool>(false);
  bool _disposed = false;

  void _init() {
    // Por enquanto, marcar como carregado imediatamente
    // TODO: Ouvir mudanças no usuário atual quando AppState estiver disponível
    _markAsLoaded();
  }

  void _markAsLoaded() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_disposed) {
        isFullyLoadedNotifier.value = true;
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    isFullyLoadedNotifier.dispose();
    super.dispose();
  }
}
