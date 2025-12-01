import 'package:flutter/material.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';

/// Tela de edição de perfil
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Implementar salvamento
              Navigator.of(context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
      body: Center(
        child: GlimpseEmptyState.standard(
          text: 'Tela de edição de perfil\nImplementar funcionalidade de edição',
        ),
      ),
    );
  }
}