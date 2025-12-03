import 'package:partiu/shared/widgets/processing.dart';
import 'package:flutter/material.dart';

/// Fullscreen white processing overlay controller.
/// Compatible API: show(message), hide().
class ProgressDialog {

  ProgressDialog(this.context, {this.isDismissible = true});
  final BuildContext context;
  final bool isDismissible;
  bool _isShowing = false;
  OverlayEntry? _entry;

  bool get isShowing => _isShowing;

  Future<bool> show(String message) async {
    try {
      if (_isShowing) return true;
      final overlay = Overlay.of(context, rootOverlay: true);
      _isShowing = true;
      _entry = OverlayEntry(
        builder: (_) => PopScope(
          canPop: isDismissible,
          child: Material(
            color: Colors.white,
            child: Processing(text: message),
          ),
        ),
      );
      overlay.insert(_entry!);
      return true;
    } catch (e) {
      _isShowing = false;
      return false;
    }
  }

  Future<bool> hide() async {
    try {
      if (!_isShowing) return true;
      _entry?.remove();
      _entry = null;
      _isShowing = false;
      return true;
    } catch (e) {
      _isShowing = false;
      return false;
    }
  }
}
