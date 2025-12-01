import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Flags para controle granular de logs por categoria
/// 
/// Ative/desative categorias individualmente para focar na área que está debugando
/// e evitar overhead desnecessário.
/// 
/// Exemplo de uso:
/// ```dart
/// LogFlags.builds = true;  // Ativa logs de rebuild
/// LogFlags.streams = false; // Desativa logs de streams
/// ```
class LogFlags {
  /// Logs de rebuilds de widgets (use com cuidado - muito verboso)
  static bool builds = false;
  
  /// Logs de streams, listeners e observadores
  static bool streams = true;
  
  /// Logs de chamadas de API e requisições HTTP
  static bool api = true;
  
  /// Logs de operações de cache
  static bool cache = false;
  
  /// Logs de seletores e queries Firestore
  static bool selectors = false;
  
  /// Logs de controllers e state management
  static bool controllers = false;
  
  /// Logs de navegação entre telas
  static bool navigation = false;
  
  /// Logs de operações de filtros
  static bool filters = false;
  
  /// Logs de autenticação e sessão
  static bool auth = true;
  
  /// Logs de analytics e métricas
  static bool analytics = false;
  
  /// Logs de push notifications
  static bool push = true;
}

/// Logger centralizado para toda a aplicação
/// 
/// Sistema profissional de logging com:
/// - Controle granular por categoria via LogFlags
/// - Modo verbose para debug profundo
/// - Zero overhead em release
/// - Integração automática com Sentry
/// 
/// Uso básico:
/// ```dart
/// AppLogger.info('User logged in', tag: 'AUTH');
/// AppLogger.error('Failed to load data', tag: 'API', error: e, stack: stackTrace);
/// ```
/// 
/// Modo verbose (debug profundo):
/// ```dart
/// AppLogger.verbose = true;
/// AppLogger.v('Detalhes internos...', tag: 'DEBUG');
/// ```
class AppLogger {
  AppLogger._(); // Construtor privado - classe estática

  /// Controle mestre - desativa TODOS os logs se false
  /// Por padrão, ativo apenas em debug mode
  static bool enabled = true; // FORÇADO PARA TRUE - TESTE
  
  /// Modo verbose - ativa logs detalhados e pesados
  /// Use apenas quando estiver investigando bugs profundos
  /// IMPORTANTE: Deixe false no dia-a-dia para evitar overhead
  static bool verbose = false;

  /// Log básico - use para mensagens simples
  /// 
  /// Automático: só loga se enabled = true
  static void log(String message, {String tag = "APP"}) {
    if (!enabled) return;
    debugPrint('📝 [$tag] $message');
  }

  /// Log verbose - use para debug profundo
  /// 
  /// Só loga se verbose = true E enabled = true
  /// CUIDADO: String interpolation pesada deve ficar fora da chamada
  /// 
  /// ERRADO (custa caro mesmo se desativado):
  /// ```dart
  /// AppLogger.v("Data: ${jsonEncode(data)}", tag: "DEBUG");
  /// ```
  /// 
  /// CERTO:
  /// ```dart
  /// if (AppLogger.verbose) {
  ///   AppLogger.v("Data: ${jsonEncode(data)}", tag: "DEBUG");
  /// }
  /// ```
  static void v(String message, {String tag = "APP"}) {
    if (!enabled || !verbose) return;
    debugPrint('🔍 [$tag] $message');
  }

  /// Log de informação geral
  /// 
  /// Use para eventos importantes mas não críticos
  static void info(String message, {String? tag}) {
    if (!enabled) return;
    debugPrint('ℹ️ [${tag ?? 'INFO'}] $message');
  }

  /// Log de sucesso
  /// 
  /// Use para operações completadas com sucesso
  static void success(String message, {String? tag}) {
    if (!enabled) return;
    debugPrint('✅ [${tag ?? 'SUCCESS'}] $message');
  }

  /// Log de aviso
  /// 
  /// Use para situações que não são erros mas merecem atenção
  static void warning(String message, {String? tag}) {
    if (!enabled) return;
    debugPrint('⚠️ [${tag ?? 'WARNING'}] $message');
  }

  /// Log de erro
  /// 
  /// Use para exceções e erros. Automaticamente envia para Sentry em produção.
  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extras,
  }) {
    // Erros sempre logam, mesmo se enabled = false
    debugPrint('❌ [${tag ?? 'ERROR'}] $message');
    
    if (error != null) {
      debugPrint('   Error: $error');
    }
    
    if (stackTrace != null && verbose) {
      debugPrint('   Stack: $stackTrace');
    }

    // Envia para Sentry apenas em produção
    if (kReleaseMode && error != null) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'message': message,
          if (tag != null) 'tag': tag,
          if (extras != null) ...extras,
        }),
      );
    }
  }

  /// Log especializado para chamadas de API
  /// 
  /// Respeita LogFlags.api para ativar/desativar
  /// Formata automaticamente requisições e respostas
  static void api(
    String method,
    String url, {
    dynamic params,
    dynamic response,
    int? statusCode,
    Duration? duration,
  }) {
    // API logs desativados para reduzir ruído no console
  }

  /// Log de navegação entre telas
  /// 
  /// Respeita LogFlags.navigation para ativar/desativar
  /// Útil para rastrear fluxo do usuário
  static void navigation(String from, String to) {
    if (!enabled || !LogFlags.navigation) return;
  }

  /// Log de evento de analytics
  /// 
  /// Respeita LogFlags.analytics para ativar/desativar
  /// Use para rastrear eventos importantes do usuário
  static void analytics(String event, {Map<String, dynamic>? properties}) {
    if (!enabled || !LogFlags.analytics) return;
    
    
    if (properties != null && verbose) {
      try {
        // TODO: Implementar logging de propriedades se necessário
      } catch (e) {
        // Silently ignore property logging errors
      }
    }
  }

  /// Log de rebuild de widgets
  /// 
  /// Respeita LogFlags.builds para ativar/desativar
  /// MUITO VERBOSO - use apenas quando investigar problemas de performance
  static void build(String widgetName, {String? reason}) {
    if (!enabled || !LogFlags.builds) return;
    debugPrint('🔄 [BUILD] $widgetName${reason != null ? ' ($reason)' : ''}');
  }

  /// Log de streams e listeners
  /// 
  /// Respeita LogFlags.streams para ativar/desativar
  static void stream(String message, {String? tag}) {
    if (!enabled || !LogFlags.streams) return;
    debugPrint('📡 [${tag ?? 'STREAM'}] $message');
  }

  /// Log de operações de cache
  /// 
  /// Respeita LogFlags.cache para ativar/desativar
  static void cache(String message, {String? tag}) {
    if (!enabled || !LogFlags.cache) return;
    debugPrint('🗄 [${tag ?? 'CACHE'}] $message');
  }

  /// Log de controllers e state management
  /// 
  /// Respeita LogFlags.controllers para ativar/desativar
  static void controller(String message, {String? tag}) {
    if (!enabled || !LogFlags.controllers) return;
    debugPrint('🎮 [${tag ?? 'CONTROLLER'}] $message');
  }

  /// Log de seletores e queries
  /// 
  /// Respeita LogFlags.selectors para ativar/desativar
  static void selector(String message, {String? tag}) {
    if (!enabled || !LogFlags.selectors) return;
    debugPrint('🔍 [${tag ?? 'SELECTOR'}] $message');
  }

  /// Log de operações de filtros
  /// 
  /// Respeita LogFlags.filters para ativar/desativar
  static void filter(String message, {String? tag}) {
    if (!enabled || !LogFlags.filters) return;
    debugPrint('🔍 [${tag ?? 'FILTER'}] $message');
  }

  /// Log de push notifications
  /// 
  /// Respeita LogFlags.push para ativar/desativar
  static void push(String message, {String? tag}) {
    if (!enabled || !LogFlags.push) return;
    debugPrint('📱 [${tag ?? 'PUSH'}] $message');
  }

  /// Métrica simples (telemetria leve)
  ///
  /// Sempre ativo (não respeita flags) pois é usado para performance monitoring
  /// 
  /// Exemplo: 
  /// ```dart
  /// AppLogger.metric(
  ///   'firestore_watch_latency_ms', 
  ///   valueMs: 430, 
  ///   tags: {'path': 'Users/123', 'type': 'document'}
  /// );
  /// ```
  static void metric(String name, {int? valueMs, Map<String, dynamic>? tags}) {
    if (!enabled) return;
    
    final buffer = StringBuffer("📈 [METRIC] $name");
    
    if (valueMs != null) {
      buffer.write(": ${valueMs}ms");
    }
    
    if (tags != null && tags.isNotEmpty && verbose) {
      buffer.write(" | ${jsonEncode(tags)}");
    }
    
  }

  /// Log de debug genérico (use com moderação)
  /// 
  /// Preferir métodos específicos (info, warning, etc)
  static void debug(String message, {String? tag}) {
    if (!enabled || !verbose) return;
    debugPrint('🐞 [${tag ?? 'DEBUG'}] $message');
  }

  /// Método para debugar estado das flags
  static void debugFlags() {
    debugPrint('🔧 [DEBUG] AppLogger.enabled = $enabled');
    debugPrint('🔧 [DEBUG] LogFlags.filters = ${LogFlags.filters}');
    debugPrint('🔧 [DEBUG] LogFlags.api = ${LogFlags.api}');
    debugPrint('🔧 [DEBUG] LogFlags.streams = ${LogFlags.streams}');
  }

  // ============================================================
  // MÉTODOS UTILITÁRIOS
  // ============================================================

  /// Ativa modo debug completo
  /// 
  /// Liga todas as flags e verbose mode
  /// Use quando precisar investigar bug complexo
  static void enableFullDebug() {
    enabled = true;
    verbose = true;
    LogFlags.builds = true;
    LogFlags.streams = true;
    LogFlags.api = true;
    LogFlags.cache = true;
    LogFlags.selectors = true;
    LogFlags.controllers = true;
    LogFlags.navigation = true;
    LogFlags.filters = true;
    LogFlags.auth = true;
    LogFlags.analytics = true;
    LogFlags.push = true;
    
    info('🔥 FULL DEBUG MODE ATIVADO', tag: 'LOGGER');
  }

  /// Desativa todos os logs
  /// 
  /// Use para máxima performance em testes
  static void disableAll() {
    enabled = false;
    verbose = false;
    LogFlags.builds = false;
    LogFlags.streams = false;
    LogFlags.api = false;
    LogFlags.cache = false;
    LogFlags.selectors = false;
    LogFlags.controllers = false;
    LogFlags.navigation = false;
    LogFlags.filters = false;
    LogFlags.auth = false;
    LogFlags.analytics = false;
    LogFlags.push = false;
  }

  /// Configuração padrão otimizada
  /// 
  /// Balanceamento ideal entre informação útil e performance
  static void setDefaultConfig() {
    enabled = kDebugMode;
    verbose = false;
    LogFlags.builds = false;        // Muito verboso
    LogFlags.streams = true;        // Útil
    LogFlags.api = true;           // Útil
    LogFlags.cache = false;        // Pode ser verboso
    LogFlags.selectors = false;    // Muito verboso
    LogFlags.controllers = false;  // Pode ser verboso
    LogFlags.navigation = false;   // Opcional
    LogFlags.filters = true;      // HABILITADO para debug
    LogFlags.auth = true;          // Importante
    LogFlags.analytics = false;    // Opcional
    LogFlags.push = true;          // Útil
  }
}
