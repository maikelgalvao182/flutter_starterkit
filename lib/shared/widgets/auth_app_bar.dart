import 'package:flutter/material.dart';
import 'package:partiu/shared/widgets/glimpse_back_button.dart';
import 'package:go_router/go_router.dart';

/// AppBar padrão para telas de autenticação
/// Usado em: EmailAuthScreen, ForgotPasswordScreen, e outras telas de auth
class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AuthAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: GlimpseBackButton.iconButton(
        onPressed: () => context.pop(),
        color: Colors.black,
      ),
      centerTitle: true,
      title: Image.asset(
        'assets/images/logo.png',
        height: 24,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
