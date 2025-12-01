import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/shared/models/user_model.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerenciador centralizado de sessão do usuário
/// 
/// Responsável por persistir e recuperar dados da sessão usando SharedPreferences.
/// Único ponto de verdade para dados do usuário logado.
/// 
/// Uso:
/// ```dart
/// // Verificar login
/// if (SessionManager.instance.isLoggedIn) {
///   final user = SessionManager.instance.currentUser;
/// }
/// 
/// // Fazer login
/// await SessionManager.instance.login(user);
/// 
/// // Fazer logout
/// await SessionManager.instance.logout();
/// ```
class SessionManager {
  SessionManager._(); // Construtor privado

  static final SessionManager _instance = SessionManager._();
  
  /// Instância singleton
  static SessionManager get instance => _instance;

  SharedPreferences? _prefs;

  /// Inicializa o SessionManager
  /// 
  /// DEVE ser chamado no main() antes de runApp():
  /// ```dart
  /// await SessionManager.instance.initialize();
  /// ```
  Future<void> initialize() async {
    if (_prefs != null) return; // Já inicializado
    
    _prefs = await SharedPreferences.getInstance();
    _log('SessionManager initialized');
  }

  SharedPreferences get _prefsOrThrow {
    if (_prefs == null) {
      throw StateError(
        'SessionManager not initialized. Call SessionManager.instance.initialize() in main()',
      );
    }
    return _prefs!;
  }

  // ==================== USER DATA ====================

  /// Usuário atualmente logado (ou null se não estiver logado)
  UserModel? get currentUser {
    try {
      final json = _prefsOrThrow.getString(_Keys.currentUser);
      if (json == null || json.isEmpty) return null;
      
      final data = jsonDecode(json) as Map<String, dynamic>;
      return UserModel(
        userId: data['userId'] as String,
        fullName: data['fullName'] as String?,
        email: data['email'] as String?,
        photoUrl: data['photoUrl'] as String?,
        userType: data['userType'] as String? ?? 'vendor',
      );
    } catch (e, stack) {
      _logError('Failed to decode current user', e, stack);
      return null;
    }
  }

  /// Define o usuário atual
  set currentUser(UserModel? user) {
    try {
      if (user == null) {
        _prefsOrThrow.remove(_Keys.currentUser);
        _log('Current user cleared');
      } else {
        final json = jsonEncode(user.toMap());
        _prefsOrThrow.setString(_Keys.currentUser, json);
        _log('Current user saved: ${user.userId}');
      }
    } catch (e, stack) {
      _logError('Failed to save current user', e, stack);
    }
  }

  /// ID do usuário atual (atalho)
  String? get currentUserId => currentUser?.userId;

  // ==================== AUTH STATE ====================

  /// Indica se o usuário está logado
  bool get isLoggedIn => _prefsOrThrow.getBool(_Keys.isLoggedIn) ?? false;

  /// Define o estado de login
  set isLoggedIn(bool value) {
    _prefsOrThrow.setBool(_Keys.isLoggedIn, value);
    _log('Login state changed: $value');
  }

  // ==================== SETTINGS ====================

  /// Idioma selecionado (código ISO: 'en', 'pt', etc)
  String get language => _prefsOrThrow.getString(_Keys.language) ?? 'pt';

  /// Define o idioma
  set language(String value) {
    _prefsOrThrow.setString(_Keys.language, value);
    _log('Language changed: $value');
  }

  /// Modo de tema (light, dark, system)
  String get themeMode => _prefsOrThrow.getString(_Keys.themeMode) ?? 'system';

  /// Define o modo de tema
  set themeMode(String value) {
    _prefsOrThrow.setString(_Keys.themeMode, value);
    _log('Theme mode changed: $value');
  }

  /// Notificações habilitadas
  bool get notificationsEnabled => 
      _prefsOrThrow.getBool(_Keys.notificationsEnabled) ?? true;

  /// Define se notificações estão habilitadas
  set notificationsEnabled(bool value) {
    _prefsOrThrow.setBool(_Keys.notificationsEnabled, value);
    _log('Notifications enabled: $value');
  }

  // ==================== ONBOARDING ====================

  /// Indica se o usuário já completou o onboarding
  bool get hasCompletedOnboarding => 
      _prefsOrThrow.getBool(_Keys.hasCompletedOnboarding) ?? false;

  /// Define se completou onboarding
  set hasCompletedOnboarding(bool value) {
    _prefsOrThrow.setBool(_Keys.hasCompletedOnboarding, value);
  }

  // ==================== FCM TOKEN ====================

  /// Token FCM para push notifications
  String? get fcmToken => _prefsOrThrow.getString(_Keys.fcmToken);

  /// Define o token FCM
  set fcmToken(String? value) {
    if (value == null) {
      _prefsOrThrow.remove(_Keys.fcmToken);
    } else {
      _prefsOrThrow.setString(_Keys.fcmToken, value);
    }
  }

  // ==================== CUSTOM DATA ====================

  /// Salva um valor customizado
  Future<bool> setCustomValue(String key, dynamic value) async {
    try {
      if (value == null) {
        return await _prefsOrThrow.remove(key);
      } else if (value is String) {
        return await _prefsOrThrow.setString(key, value);
      } else if (value is int) {
        return await _prefsOrThrow.setInt(key, value);
      } else if (value is double) {
        return await _prefsOrThrow.setDouble(key, value);
      } else if (value is bool) {
        return await _prefsOrThrow.setBool(key, value);
      } else if (value is List<String>) {
        return await _prefsOrThrow.setStringList(key, value);
      } else {
        // Para objetos complexos, serializa como JSON
        final safe = _sanitizeForJson(value);
        return await _prefsOrThrow.setString(key, jsonEncode(safe));
      }
    } catch (e, stack) {
      _logError('Failed to save custom value for key: $key', e, stack);
      return false;
    }
  }

  /// Recupera um valor customizado
  dynamic getCustomValue(String key, {dynamic defaultValue}) {
    return _prefsOrThrow.get(key) ?? defaultValue;
  }

  /// Converte estruturas contendo tipos do Firestore (Timestamp, GeoPoint, DocumentReference)
  /// em representações JSON-safe de forma recursiva.
  dynamic _sanitizeForJson(dynamic value) {
    if (value == null) return null;

    // Firestore Timestamp -> ISO8601
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    // DateTime -> ISO8601
    if (value is DateTime) {
      return value.toIso8601String();
    }
    // Firestore GeoPoint -> Map
    if (value is GeoPoint) {
      return {
        'latitude': value.latitude,
        'longitude': value.longitude,
      };
    }
    // DocumentReference -> path
    if (value is DocumentReference) {
      return value.path;
    }
    // Map recursivo
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((key, val) {
        out[key.toString()] = _sanitizeForJson(val);
      });
      return out;
    }
    // List/Set recursivo
    if (value is Iterable) {
      return value.map(_sanitizeForJson).toList(growable: false);
    }

    return value;
  }

  // ==================== SESSION MANAGEMENT ====================

  /// Faz login do usuário
  /// 
  /// Salva o usuário, marca como logado e opcionalmente guarda metadados
  /// 
  /// [user] - Dados do usuário
  /// [token] - Token JWT/OAuth (opcional)
  /// [deviceId] - ID do dispositivo (opcional)
  Future<void> login(
    UserModel user, {
    String? token,
    String? deviceId,
  }) async {
    currentUser = user;
    isLoggedIn = true;
    
    // Salva metadados opcionais
    if (token != null) {
      await setCustomValue(_Keys.authToken, token);
    }
    if (deviceId != null) {
      await setCustomValue(_Keys.deviceId, deviceId);
    }
    
    _log('User logged in: ${user.userId}');
  }
  
  /// Token de autenticação (JWT/OAuth)
  String? get authToken => _prefsOrThrow.getString(_Keys.authToken);
  
  /// Define token de autenticação
  set authToken(String? value) {
    if (value == null) {
      _prefsOrThrow.remove(_Keys.authToken);
    } else {
      _prefsOrThrow.setString(_Keys.authToken, value);
    }
  }
  
  /// ID do dispositivo
  String? get deviceId => _prefsOrThrow.getString(_Keys.deviceId);

  /// Faz logout do usuário
  /// 
  /// Limpa TODOS os dados da sessão, mas preserva configurações do app
  Future<void> logout() async {
    _log('Logging out user: ${currentUserId ?? 'unknown'}');
    
    // Preserva configurações que devem persistir
    final savedLanguage = language;
    final savedTheme = themeMode;
    final savedOnboarding = hasCompletedOnboarding;
    
    // Limpa todos os dados
    await Future(() async {
      await _prefsOrThrow.clear();
      await _prefsOrThrow.reload();
    });
    
    // Restaura configurações preservadas
    language = savedLanguage;
    themeMode = savedTheme;
    hasCompletedOnboarding = savedOnboarding;
    
    // Limpa caches externos
    await _clearExternalCaches();
    
    _log('User logged out successfully');
  }

  /// Limpa TUDO (incluindo configurações do app)
  /// 
  /// Use apenas ao deletar conta ou resetar app completamente
  Future<void> clearAll() async {
    _log('Clearing ALL session data');
    
    await Future(() async {
      await _prefsOrThrow.clear();
      await _prefsOrThrow.reload();
    });
    
    await _clearExternalCaches();
    
    _log('All session data cleared');
  }

  /// Limpa caches externos (imagens, dados, etc)
  Future<void> _clearExternalCaches() async {
    try {
      // Limpa cache de imagens
      await DefaultCacheManager().emptyCache();
      _log('Image cache cleared');
    } catch (e, stack) {
      _logError('Error clearing external caches', e, stack);
    }
  }

  // ==================== DEBUG ====================

  /// Lista todas as chaves armazenadas (debug only)
  Set<String> getAllKeys() {
    return _prefsOrThrow.getKeys();
  }

  /// Imprime estado da sessão (debug only)
  void printSessionState() {
    _log('=== SESSION STATE ===');
    _log('Logged in: $isLoggedIn');
    _log('User ID: ${_maskSensitiveData(currentUserId)}');
    _log('Language: $language');
    _log('Theme: $themeMode');
    _log('Notifications: $notificationsEnabled');
    _log('Onboarding: $hasCompletedOnboarding');
    _log('Has auth token: ${authToken != null}');
    _log('====================');
  }
  
  /// Mascara dados sensíveis para logs
  String _maskSensitiveData(String? data) {
    if (data == null || data.isEmpty) return 'none';
    if (data.length <= 4) return '****';
    
    // Mostra primeiros 4 e últimos 4 caracteres
    final start = data.substring(0, 4);
    final end = data.substring(data.length - 4);
    return '$start****$end';
  }

  // ==================== LOGGING ====================

  void _log(String message) {
    developer.log(message, name: 'partiu.session');
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'partiu.session',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Chaves usadas no SharedPreferences
class _Keys {
  static const String currentUser = 'session_current_user';
  static const String isLoggedIn = 'session_is_logged_in';
  static const String language = 'session_language';
  static const String themeMode = 'session_theme_mode';
  static const String notificationsEnabled = 'session_notifications_enabled';
  static const String hasCompletedOnboarding = 'session_has_completed_onboarding';
  static const String fcmToken = 'session_fcm_token';
  static const String authToken = 'session_auth_token';
  static const String deviceId = 'session_device_id';
}
