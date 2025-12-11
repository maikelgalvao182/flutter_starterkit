import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/features/profile/data/services/profile_visits_service.dart';

/// Controller SINGLETON para visitas ao perfil (padrão LocationQueryService)
/// 
/// Arquitetura:
/// - ✅ Escuta stream do ProfileVisitsService (não do Firestore diretamente)
/// - ✅ Service gerencia cache, TTL, reload e acesso ao Firestore
/// - ✅ Controller só mantém lista local e atualiza UI
/// - ✅ Scroll não reseta, apenas cards mudam
/// 
/// Uso:
/// ```dart
/// ProfileVisitsController.instance.watchUser(userId);
/// 
/// AnimatedBuilder(
///   animation: ProfileVisitsController.instance,
///   builder: (context, _) => ListView(...)
/// )
/// ```
class ProfileVisitsController extends ChangeNotifier {
  ProfileVisitsController._() {
    _initializeStream();
  }
  
  static final ProfileVisitsController _instance = ProfileVisitsController._();
  static ProfileVisitsController get instance => _instance;

  final _service = ProfileVisitsService.instance;

  // Lista local de visitantes
  List<User> _visitors = [];
  
  // Estado
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;
  
  // Subscription do stream do service
  StreamSubscription<List<User>>? _visitsSubscription;
  
  // 🚀 Paginação para listas grandes
  int _displayedCount = 20; // Mostra 20 inicialmente
  
  // Getters
  List<User> get visitors => _visitors;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _visitors.isEmpty && !_isLoading;
  String? get currentUserId => _currentUserId;
  
  // 🚀 Getters de paginação
  List<User> get displayedVisitors => _visitors.take(_displayedCount).toList();
  bool get hasMore => _displayedCount < _visitors.length;
  bool get isLoadingMore => false; // Dados já estão em memória

  /// Inicializa listener do stream do service
  void _initializeStream() {
    debugPrint('🎧 [ProfileVisitsController] Inicializando stream');
    
    _visitsSubscription = _service.visitsStream.listen(
      _onVisitsChanged,
      onError: _onVisitsError,
    );
  }

  /// Monitora visitas de um userId
  void watchUser(String userId) {
    if (_currentUserId == userId) {
      debugPrint('👀 [ProfileVisitsController] Já monitorando $userId');
      return;
    }

    debugPrint('👀 [ProfileVisitsController] Monitorando visitas de $userId');
    
    _currentUserId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Service cuida de tudo (cache, query, stream)
    _service.watchUser(userId);
  }

  /// Callback quando visitas mudam no stream
  void _onVisitsChanged(List<User> newVisitors) {
    debugPrint('📥 [ProfileVisitsController] Stream recebeu ${newVisitors.length} visitantes');
    
    _visitors = newVisitors;
    _isLoading = false;
    _error = null;
    
    // 🚀 Reset de paginação se lista mudou significativamente
    if (newVisitors.length < _displayedCount) {
      _displayedCount = 20;
    }
    
    notifyListeners();
  }
  
  /// Carrega mais visitantes (paginação local - dados já estão em memória)
  /// 
  /// 🚀 Usado com InfiniteListView para scroll infinito
  void loadMore() {
    if (!hasMore) return;
    
    final newCount = (_displayedCount + 20).clamp(0, _visitors.length);
    debugPrint('📄 [ProfileVisitsController] LoadMore: $_displayedCount -> $newCount');
    
    _displayedCount = newCount;
    notifyListeners();
  }

  /// Callback quando ocorre erro no stream
  void _onVisitsError(Object error) {
    debugPrint('❌ [ProfileVisitsController] Erro no stream: $error');
    
    _error = 'Erro ao carregar visitas';
    _isLoading = false;
    notifyListeners();
  }

  /// Força reload (invalida cache e recarrega)
  Future<void> refresh() async {
    if (_currentUserId == null) return;
    
    debugPrint('🔄 [ProfileVisitsController] Refresh solicitado');
    await _service.forceReload(_currentUserId!);
  }

  @override
  void dispose() {
    _visitsSubscription?.cancel();
    super.dispose();
  }
}
