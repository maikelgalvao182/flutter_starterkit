import 'package:partiu/core/constants/toast_constants.dart';
import 'package:flutter/material.dart';

/// Serviço para exibição de toasts personalizados com animação
class ToastService {
  
  /// Exibe uma notificação de sucesso (verde)
  static void showSuccess({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration? duration,
    bool persistent = false,
  }) {
    _showCustomToast(
      context: context,
      title: title,
      subtitle: subtitle,
      backgroundColor: ToastConstants.successBackgroundColor,
      textColor: ToastConstants.successAccentColor,
      iconData: ToastConstants.successIcon,
      iconColor: ToastConstants.successAccentColor,
      border: ToastConstants.successBorder,
      duration: duration ?? ToastConstants.defaultDuration,
    );
  }
  
  /// Exibe uma notificação de erro (vermelho)
  static void showError({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration? duration,
    bool persistent = false,
  }) {
    _showCustomToast(
      context: context,
      title: title,
      subtitle: subtitle,
      backgroundColor: ToastConstants.errorBackgroundColor,
      textColor: ToastConstants.errorAccentColor,
      iconData: ToastConstants.errorIcon,
      iconColor: ToastConstants.errorAccentColor,
      border: ToastConstants.errorBorder,
      duration: duration ?? ToastConstants.defaultDuration,
    );
  }
  
  /// Exibe uma notificação de informação (azul)
  static void showInfo({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration? duration,
    bool persistent = false,
  }) {
    _showCustomToast(
      context: context,
      title: title,
      subtitle: subtitle,
      backgroundColor: ToastConstants.infoBackgroundColor,
      textColor: ToastConstants.infoAccentColor,
      iconData: ToastConstants.infoIcon,
      iconColor: ToastConstants.infoAccentColor,
      border: ToastConstants.infoBorder,
      duration: duration ?? ToastConstants.defaultDuration,
    );
  }
  
  /// Exibe uma notificação de aviso (laranja)
  static void showWarning({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration? duration,
    bool persistent = false,
  }) {
    _showCustomToast(
      context: context,
      title: title,
      subtitle: subtitle,
      backgroundColor: ToastConstants.warningBackgroundColor,
      textColor: ToastConstants.warningAccentColor,
      iconData: ToastConstants.warningIcon,
      iconColor: ToastConstants.warningAccentColor,
      border: ToastConstants.warningBorder,
      duration: duration ?? ToastConstants.defaultDuration,
    );
  }

  // === MÉTODOS DE CONVENIÊNCIA PARA SUBSTITUIR DIÁLOGOS ===
  
  /// Exibe notificação de sucesso (substitui successDialog)
  static void showSuccessDialog({
    required BuildContext context,
    required String message,
    String? title,
    Duration? duration,
  }) {
    showSuccess(
      context: context,
      title: title ?? 'Success',
      subtitle: message,
      duration: duration,
    );
  }
  
  /// Exibe notificação de erro (substitui errorDialog)
  static void showErrorDialog({
    required BuildContext context,
    required String message,
    String? title,
    Duration? duration,
  }) {
    showError(
      context: context,
      title: title ?? 'Error',
      subtitle: message,
      duration: duration,
    );
  }
  
  /// Exibe notificação de confirmação (substitui confirmDialog)
  static void showConfirmDialog({
    required BuildContext context,
    required String message,
    String? title,
    Duration? duration,
  }) {
    showSuccess(
      context: context,
      title: title ?? 'Confirmed',
      subtitle: message,
      duration: duration,
    );
  }
  
  /// Exibe notificação de informação (substitui infoDialog)
  static void showInfoDialog({
    required BuildContext context,
    required String message,
    String? title,
    Duration? duration,
  }) {
    showInfo(
      context: context,
      title: title ?? 'Information',
      subtitle: message,
      duration: duration,
    );
  }

  /// Método interno para exibir toast customizado com animação
  static void _showCustomToast({
    required BuildContext context,
    required String title,
    required Color backgroundColor, required Color textColor, required IconData iconData, required Color iconColor, required Border border, String? subtitle,
    Duration? duration,
  }) {
    // If the context is already deactivated, abort to avoid ancestor lookups
    try {
      // BuildContext.mounted is safe to check and avoids using deactivated contexts
      // If not available in older SDKs, the try/catch prevents crashes
      // ignore: unnecessary_null_comparison
      final bool isMounted = ((context as dynamic).mounted as bool?) ?? true;
      if (!isMounted) return;
    } catch (_) {
      // If anything goes wrong determining mounted state, proceed cautiously
    }

    // Tenta obter overlay diretamente
    OverlayState? overlayState;
    try {
      overlayState = Overlay.maybeOf(context, rootOverlay: true);
    } catch (_) {
      // ignore
    }
    if (overlayState == null) {
      try {
        overlayState = Overlay.maybeOf(context, rootOverlay: true);
      } catch (_) {
        // ignore
      }
    }
    if (overlayState == null) {
      try {
        overlayState = Overlay.maybeOf(context);
      } catch (_) {
        // ignore
      }
    }

    if (overlayState == null) {
      // If still null, abort silently to avoid crashing the app
      return;
    }

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (ctx) => _AnimatedNotification(
        title: title,
        subtitle: subtitle,
        backgroundColor: backgroundColor,
        textColor: textColor,
        iconData: iconData,
        iconColor: iconColor,
        border: border,
        duration: duration ?? ToastConstants.defaultDuration,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    try {
      overlayState.insert(overlayEntry);
    } catch (_) {
      // If insertion fails due to disposed overlay, ignore gracefully
    }
  }
}

/// Widget de notificação animada que desliza de cima para baixo
class _AnimatedNotification extends StatefulWidget {

  const _AnimatedNotification({
    required this.title,
    required this.backgroundColor, required this.textColor, required this.iconData, required this.iconColor, required this.border, required this.duration, required this.onDismiss, this.subtitle,
  });
  final String title;
  final String? subtitle;
  final Color backgroundColor;
  final Color textColor;
  final IconData iconData;
  final Color iconColor;
  final Border border;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_AnimatedNotification> createState() => _AnimatedNotificationState();
}

class _AnimatedNotificationState extends State<_AnimatedNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  static const _enterDuration = Duration(milliseconds: 500);
  static const _exitDuration = Duration(milliseconds: 300);
  static const _toastRadius = BorderRadius.all(Radius.circular(12));

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: _enterDuration,
      reverseDuration: _exitDuration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Começa de cima (fora da tela)
      end: Offset.zero, // Termina na posição normal
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    // Inicia a animação de entrada
    _controller.forward();

    // Programa a saída após a duração especificada
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: GestureDetector(
              onTap: () {
                // Ao clicar, acelera a saída do toast
                if (mounted) {
                  _controller.reverse().then((_) => widget.onDismiss());
                }
              },
              child: RepaintBoundary(
                child: Container(
                  width: double.infinity, // Largura total
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20, // Considera safe area
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: _toastRadius,
                    border: widget.border,
                    boxShadow: ToastConstants.boxShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.iconData,
                        color: widget.iconColor,
                        size: ToastConstants.iconSize,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                color: widget.textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  color: widget.textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
