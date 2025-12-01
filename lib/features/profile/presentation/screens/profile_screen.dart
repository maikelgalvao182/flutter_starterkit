import 'package:flutter/material.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';

/// Tela de visualização de perfil
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.currentUserId,
  });

  final User user;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil de ${user.userFullname}'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Center(
        child: GlimpseEmptyState.standard(
          text: 'Tela de visualização de perfil\nUsuário: ${user.userFullname}\nID: ${user.userId}',
        ),
      ),
    );
  }
}