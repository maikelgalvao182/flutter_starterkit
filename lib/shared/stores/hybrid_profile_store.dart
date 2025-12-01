import 'package:flutter/foundation.dart';
import 'package:partiu/common/state/app_state.dart';

/// Store híbrido para dados de perfil
/// Combina dados locais com streams reativos
class HybridProfileStore extends ChangeNotifier {
  static final HybridProfileStore _instance = HybridProfileStore._internal();
  static HybridProfileStore get instance => _instance;
  HybridProfileStore._internal();

  // Notifiers reativos para UI granular
  final Map<String, ValueNotifier<String?>> _cityNotifiers = {};
  final Map<String, ValueNotifier<String?>> _stateNotifiers = {};

  /// Obtém notifier reativo para cidade
  ValueNotifier<String?> getCityNotifier(String userId) {
    if (userId.isEmpty) return ValueNotifier<String?>(null);
    
    return _cityNotifiers.putIfAbsent(userId, () {
      final notifier = ValueNotifier<String?>(null);
      _loadUserLocation(userId);
      return notifier;
    });
  }

  /// Obtém notifier reativo para estado
  ValueNotifier<String?> getStateNotifier(String userId) {
    if (userId.isEmpty) return ValueNotifier<String?>(null);
    
    return _stateNotifiers.putIfAbsent(userId, () {
      final notifier = ValueNotifier<String?>(null);
      _loadUserLocation(userId);
      return notifier;
    });
  }

  /// Carrega localização do usuário
  void _loadUserLocation(String userId) {
    // Por agora, usa dados do AppState
    final currentUser = AppState.currentUser.value;
    if (currentUser?.userId == userId) {
      _cityNotifiers[userId]?.value = currentUser?.userLocality ?? '';
      _stateNotifiers[userId]?.value = currentUser?.userState ?? '';
    }
    
    // TODO: Implementar busca via API/Firebase para outros usuários
  }

  /// Atualiza localização de um usuário
  void updateUserLocation(String userId, String? city, String? state) {
    _cityNotifiers[userId]?.value = city;
    _stateNotifiers[userId]?.value = state;
  }

  /// Limpa cache de um usuário
  void clearUserCache(String userId) {
    _cityNotifiers.remove(userId)?.dispose();
    _stateNotifiers.remove(userId)?.dispose();
  }

  @override
  void dispose() {
    for (final notifier in _cityNotifiers.values) {
      notifier.dispose();
    }
    for (final notifier in _stateNotifiers.values) {
      notifier.dispose();
    }
    _cityNotifiers.clear();
    _stateNotifiers.clear();
    super.dispose();
  }
}