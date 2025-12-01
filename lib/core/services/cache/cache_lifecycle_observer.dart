import 'dart:async';
import 'package:flutter/material.dart';
import 'package:partiu/core/services/cache/cache_manager.dart';
import 'dart:developer' as developer;

/// Observer de lifecycle do app para gerenciar cache automaticamente
/// 
/// Responsabilidades:
/// - Limpa cache expirado quando app volta do background
/// - Limpa cache periodicamente (a cada 5 minutos)
/// - Limpa cache antes do app fechar
/// - Detecta memory warnings (iOS/Android)
/// 
/// Uso no main.dart:
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Inicializa Firebase, SessionManager, etc...
///   
///   // Inicializa cache system
///   CacheManager.instance.initialize();
///   
///   // Registra lifecycle observer
///   final observer = CacheLifecycleObserver();
///   WidgetsBinding.instance.addObserver(observer);
///   observer.startPeriodicCleanup();
///   
///   runApp(MyApp());
/// }
/// ```
class CacheLifecycleObserver extends WidgetsBindingObserver {
  Timer? _periodicCleanupTimer;
  List<String>? _criticalUserIds;
  
  /// Inicia limpeza periódica automática (a cada 5 minutos)
  /// 
  /// Chame após inicializar o cache system.
  void startPeriodicCleanup({Duration interval = const Duration(minutes: 5)}) {
    _log('Starting periodic cache cleanup (interval: ${interval.inMinutes}m)');
    
    _periodicCleanupTimer?.cancel();
    _periodicCleanupTimer = Timer.periodic(interval, (_) {
      _log('Running periodic cache cleanup...');
      CacheManager.instance.cleanExpired();
    });
  }
  
  /// Para limpeza periódica
  void stopPeriodicCleanup() {
    _periodicCleanupTimer?.cancel();
    _periodicCleanupTimer = null;
    _log('Periodic cache cleanup stopped');
  }
  
  /// Define usuários críticos que devem ser revalidados ao voltar do background
  /// 
  /// Exemplo: usuário logado, participantes de conversas ativas, etc.
  void setCriticalUserIds(List<String> userIds) {
    _criticalUserIds = userIds;
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // ✅ App voltou do background → limpa cache expirado
        _log('App resumed → refreshing cache');
        CacheManager.instance.refreshOnForeground(
          criticalUserIds: _criticalUserIds,
        );
        break;
        
      case AppLifecycleState.paused:
        // ✅ App foi para background → limpa cache expirado (economiza memória)
        _log('App paused → cleaning expired cache');
        CacheManager.instance.cleanExpired();
        break;
        
      case AppLifecycleState.inactive:
        // App está em transição (ex: recebendo ligação)
        // Não faz nada
        break;
        
      case AppLifecycleState.detached:
        // ✅ App está fechando → limpa cache expirado
        _log('App detached → cleaning expired cache');
        CacheManager.instance.cleanExpired();
        break;
        
      case AppLifecycleState.hidden:
        // App está oculto (novo no Flutter 3.13+)
        break;
    }
  }
  
  @override
  void didHaveMemoryPressure() {
    // ⚠️ Sistema operacional pedindo para liberar memória
    _log('Memory pressure detected → cleaning ALL expired cache');
    CacheManager.instance.cleanExpired();
    
    // Se pressão for crítica, pode limpar avatares mais agressivamente
    CacheManager.instance.avatars.cleanOld(maxAge: Duration(minutes: 30));
  }
  
  /// Limpa recursos ao destruir observer
  void dispose() {
    stopPeriodicCleanup();
    WidgetsBinding.instance.removeObserver(this);
    _log('CacheLifecycleObserver disposed');
  }
  
  void _log(String message) {
    developer.log(message, name: 'partiu.cache.lifecycle');
  }
}

/// Widget que automaticamente registra o lifecycle observer
/// 
/// Uso simplificado - envolva seu MaterialApp:
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Inicializa Firebase, SessionManager, Cache...
///   
///   runApp(
///     CacheLifecycleWrapper(
///       criticalUserIds: () => [SessionManager.instance.currentUserId],
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
class CacheLifecycleWrapper extends StatefulWidget {
  final Widget child;
  final List<String> Function()? criticalUserIds;
  final Duration cleanupInterval;
  
  const CacheLifecycleWrapper({
    super.key,
    required this.child,
    this.criticalUserIds,
    this.cleanupInterval = const Duration(minutes: 5),
  });
  
  @override
  State<CacheLifecycleWrapper> createState() => _CacheLifecycleWrapperState();
}

class _CacheLifecycleWrapperState extends State<CacheLifecycleWrapper> {
  late final CacheLifecycleObserver _observer;
  
  @override
  void initState() {
    super.initState();
    
    _observer = CacheLifecycleObserver();
    WidgetsBinding.instance.addObserver(_observer);
    
    // Inicia limpeza periódica
    _observer.startPeriodicCleanup(interval: widget.cleanupInterval);
    
    // Define usuários críticos (se fornecido)
    if (widget.criticalUserIds != null) {
      _observer.setCriticalUserIds(widget.criticalUserIds!());
    }
  }
  
  @override
  void dispose() {
    _observer.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
