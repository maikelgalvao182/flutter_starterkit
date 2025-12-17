import 'package:flutter/material.dart';
import 'package:partiu/features/notifications/controllers/simplified_notification_controller.dart';
import 'package:partiu/features/notifications/widgets/simplified_notification_screen.dart';

/// Wrapper para instanciar o SimplifiedNotificationScreen com suas dependências
class SimplifiedNotificationScreenWrapper extends StatefulWidget {
  const SimplifiedNotificationScreenWrapper({super.key});

  @override
  State<SimplifiedNotificationScreenWrapper> createState() =>
      _SimplifiedNotificationScreenWrapperState();
}

class _SimplifiedNotificationScreenWrapperState
    extends State<SimplifiedNotificationScreenWrapper> {
  // Usa o Singleton do controller
  final SimplifiedNotificationController _controller = SimplifiedNotificationController.instance;

  @override
  void initState() {
    super.initState();
    // Não precisamos instanciar nada aqui, o Singleton já cuida disso
  }

  @override
  void dispose() {
    // NÃO fazemos dispose do controller aqui pois ele é um Singleton
    // e deve manter o estado vivo entre navegações
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimplifiedNotificationScreen(
      controller: _controller,
      onBackPressed: () => Navigator.of(context).pop(),
    );
  }
}
