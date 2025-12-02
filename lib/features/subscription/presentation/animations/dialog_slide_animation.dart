import 'package:flutter/material.dart';

/// Gerencia animações de entrada e saída do dialog de assinatura
/// 
/// Responsabilidades:
/// - Animação de slide (bottom → top)
/// - Animação de fade (opacity)
/// - Controle de estado de fechamento
/// 
/// Uso:
/// ```dart
/// class _MyDialogState extends State<MyDialog> with SingleTickerProviderStateMixin {
///   late final DialogSlideAnimation _animation;
///   
///   @override
///   void initState() {
///     super.initState();
///     _animation = DialogSlideAnimation(vsync: this);
///     _animation.enter();
///   }
///   
///   @override
///   void dispose() {
///     _animation.dispose();
///     super.dispose();
///   }
/// }
/// ```
class DialogSlideAnimation {

  DialogSlideAnimation({required this.vsync}) {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: vsync,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Começa fora da tela (abaixo)
      end: Offset.zero, // Termina na posição normal
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }
  final TickerProvider vsync;
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  bool _isClosing = false;

  /// Animation controller (para usar em AnimatedBuilder)
  AnimationController get controller => _controller;

  /// Animação de slide (para SlideTransition)
  Animation<Offset> get slideAnimation => _slideAnimation;

  /// Animação de fade (para FadeTransition)
  Animation<double> get fadeAnimation => _fadeAnimation;

  /// Indica se o dialog está em processo de fechamento
  bool get isClosing => _isClosing;

  /// Inicia animação de entrada
  void enter() {
    _controller.forward();
  }

  /// Fecha o dialog com animação de saída
  /// 
  /// [context] - BuildContext para fechar o Navigator
  /// [returnSuccess] - Valor de retorno ao fechar (para indicar compra bem-sucedida)
  Future<void> close(BuildContext context, {bool returnSuccess = false}) async {
    if (_isClosing) return;
    _isClosing = true;

    // Anima saída
    await _controller.reverse();

    // Fecha dialog via Navigator
    if (context.mounted) {
      Navigator.of(context).pop(returnSuccess);
    }
  }

  /// Libera recursos
  void dispose() {
    _controller.dispose();
  }
}
