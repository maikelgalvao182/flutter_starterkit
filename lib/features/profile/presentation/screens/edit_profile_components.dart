import 'package:flutter/material.dart';

/// Componentes auxiliares para o EditProfileScreen
class EditProfileComponents {
  /// Estilo para labels
  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  /// Estilo para hints
  static const TextStyle hintStyle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  /// Decoração para campos de texto
  static InputDecoration textFieldDecoration({
    required String hintText,
    String? labelText,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  /// Widget de loading
  static Widget buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando perfil...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget de erro
  static Widget buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar perfil',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
}