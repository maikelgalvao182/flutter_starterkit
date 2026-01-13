import 'package:firebase_storage/firebase_storage.dart';

/// Gera uma cacheKey estável para imagens.
///
/// Problema que resolve:
/// - URLs de download do Firebase Storage podem conter token/querystring mutável.
/// - Se o app usar a URL inteira como chave, o cache vira "miss" mesmo para o mesmo arquivo.
///
/// Estratégia:
/// - Se for um URL do Firebase Storage: usa `fullPath` como chave (estável).
/// - Caso contrário: fallback para a URL inteira.
String stableImageCacheKey(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  try {
    final ref = FirebaseStorage.instance.refFromURL(trimmed);
    // Prefixo evita colisão com URLs externas.
    return 'fs:${ref.fullPath}';
  } catch (_) {
    return trimmed;
  }
}
