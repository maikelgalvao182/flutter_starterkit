import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para controlar exibição do onboarding após primeiro cadastro.
/// 
/// O onboarding é exibido apenas uma vez por usuário, após o primeiro
/// scroll no mapa da tela inicial. Usa SharedPreferences para persistir
/// o estado entre sessões.
class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  static const String _tag = 'OnboardingService';
  static const String _keyOnboardingCompleted = 'boora_onboarding_completed_v1';
  static const String _keyFirstMapScroll = 'boora_first_map_scroll_v1';

  // Firestore (por usuário)
  static const String _usersCollection = 'Users';
  static const String _usersCollectionLegacy = 'users';
  static const String _fieldOnboardingComplete = 'onboardingComplete';

  /// Verifica se o onboarding já foi completado
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_keyOnboardingCompleted) ?? false;
      AppLogger.debug('Onboarding completed: $completed', tag: _tag);

      // Fast path (local)
      if (completed) return true;

      // Fallback (Firestore) — garante persistência por usuário e após reinstalação
      final userId = AppState.currentUserId;
      if (userId == null || userId.isEmpty) return false;

      final remoteCompleted = await _getRemoteOnboardingComplete(userId);
      if (remoteCompleted == true) {
        await prefs.setBool(_keyOnboardingCompleted, true);
        return true;
      }

      return completed;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao verificar onboarding',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return true; // Em caso de erro, assume que já viu para não bloquear UX
    }
  }

  /// Verifica se já houve o primeiro scroll no mapa
  Future<bool> hasFirstMapScrollOccurred() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyFirstMapScroll) ?? false;
    } catch (e) {
      AppLogger.error('Erro ao verificar primeiro scroll: $e', tag: _tag);
      return true;
    }
  }

  /// Marca que o primeiro scroll no mapa ocorreu
  Future<void> markFirstMapScroll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFirstMapScroll, true);
      AppLogger.info('Primeiro scroll no mapa marcado', tag: _tag);
    } catch (e) {
      AppLogger.error('Erro ao marcar primeiro scroll: $e', tag: _tag);
    }
  }

  /// Marca o onboarding como completado
  Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOnboardingCompleted, true);
      AppLogger.info('Onboarding marcado como completado', tag: _tag);

      // Persistir também no Firestore (por usuário)
      final userId = AppState.currentUserId;
      if (userId == null || userId.isEmpty) return;

      await _setRemoteOnboardingComplete(userId, true);
    } catch (e) {
      AppLogger.error('Erro ao marcar onboarding: $e', tag: _tag);
    }
  }

  /// Verifica se deve mostrar o onboarding
  /// Retorna true se: ainda não completou E o primeiro scroll já ocorreu
  Future<bool> shouldShowOnboarding() async {
    AppLogger.debug('shouldShowOnboarding chamado', tag: _tag);

    final completed = await isOnboardingCompleted();
    if (completed) {
      AppLogger.debug('Onboarding já completado -> false', tag: _tag);
      return false;
    }

    final scrollOccurred = await hasFirstMapScrollOccurred();
    AppLogger.debug('scrollOccurred: $scrollOccurred', tag: _tag);
    return scrollOccurred;
  }

  Future<bool?> _getRemoteOnboardingComplete(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final doc = await firestore.collection(_usersCollection).doc(userId).get();
      if (doc.exists) {
        final value = doc.data()?[_fieldOnboardingComplete];
        if (value is bool) return value;
      }

      // Compatibilidade: alguns pontos do app ainda usam `users`
      final legacyDoc = await firestore.collection(_usersCollectionLegacy).doc(userId).get();
      if (legacyDoc.exists) {
        final value = legacyDoc.data()?[_fieldOnboardingComplete];
        if (value is bool) return value;
      }

      return null;
    } catch (e, stackTrace) {
      // Não bloqueia UX se Firestore falhar
      AppLogger.error(
        'Erro ao buscar onboardingComplete no Firestore',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _setRemoteOnboardingComplete(String userId, bool complete) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection(_usersCollection).doc(userId).set(
        {_fieldOnboardingComplete: complete},
        SetOptions(merge: true),
      );

      // Compatibilidade: gravar também em `users`
      await firestore.collection(_usersCollectionLegacy).doc(userId).set(
        {_fieldOnboardingComplete: complete},
        SetOptions(merge: true),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao salvar onboardingComplete no Firestore',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Reseta o estado do onboarding (útil para debug/testes)
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOnboardingCompleted);
      await prefs.remove(_keyFirstMapScroll);
      AppLogger.info('Onboarding resetado', tag: _tag);
    } catch (e) {
      AppLogger.error('Erro ao resetar onboarding: $e', tag: _tag);
    }
  }
}
