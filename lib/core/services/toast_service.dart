import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

/// Serviço para exibição de toasts
/// 
/// Usa Fluttertoast para exibir mensagens toast na parte inferior da tela
/// com cores definidas em GlimpseColors e sem decorações de texto.
class ToastService {
  
  /// Exibe um toast de sucesso (verde)
  static void showSuccess({
    required String message,
    Duration? duration,
  }) {
    _showToast(
      message: message,
      backgroundColor: GlimpseColors.success,
      textColor: Colors.white,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
  
  /// Exibe um toast de erro (vermelho)
  static void showError({
    required String message,
    Duration? duration,
  }) {
    _showToast(
      message: message,
      backgroundColor: GlimpseColors.error,
      textColor: Colors.white,
      duration: duration ?? const Duration(seconds: 4),
    );
  }
  
  /// Exibe um toast de informação (azul)
  static void showInfo({
    required String message,
    Duration? duration,
  }) {
    _showToast(
      message: message,
      backgroundColor: GlimpseColors.info,
      textColor: Colors.white,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
  
  /// Exibe um toast de aviso (laranja)
  static void showWarning({
    required String message,
    Duration? duration,
  }) {
    _showToast(
      message: message,
      backgroundColor: GlimpseColors.warning,
      textColor: Colors.white,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Método interno para exibir Toast
  static void _showToast({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required Duration duration,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: duration.inSeconds <= 3 ? Toast.LENGTH_SHORT : Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: duration.inSeconds,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 14.0,
    );
  }
}