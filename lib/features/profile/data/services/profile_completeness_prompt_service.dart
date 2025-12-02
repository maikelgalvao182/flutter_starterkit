import 'dart:async';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/managers/session_manager.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/features/profile/domain/calculators/i_profile_completeness_calculator.dart';
import 'package:partiu/features/profile/domain/calculators/vendor_profile_completeness_calculator.dart';
import 'package:partiu/features/profile/presentation/dialogs/profile_completeness_dialog.dart';
import 'package:partiu/features/profile/presentation/screens/edit_profile_screen_advanced.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsável por decidir quando exibir o bottom sheet de
/// "Profile Completeness" ao usuário no Profile Tab.
///
/// Regras:
/// - Calcula a completude do perfil usando a calculadora de vendor
/// - Exibe somente se percentage < [threshold]
/// - Respeita cooldown (não mostrar novamente dentro de 24h)
/// - Respeita dismiss definitivo (Don't show novamente - persistente via SharedPreferences)
/// - Evita múltiplas chamadas concorrentes com lock simples
class ProfileCompletenessPromptService {
  ProfileCompletenessPromptService._();
  static final ProfileCompletenessPromptService instance = ProfileCompletenessPromptService._();
  
  static const String _tag = 'ProfileCompletenessPrompt';

  static const _prefsDismissKeyPrefix = 'pc_prompt_dismiss_v1:'; // definitivo
  static const _prefsCooldownKeyPrefix = 'pc_prompt_last_seen_v1:'; // timestamp último show

  // Defaults
  int threshold = 100; // Mostrar enquanto perfil não estiver completo
  Duration cooldown = const Duration(hours: 24); // Não repetir em menos de 24h

  // Evita reentrância
  bool _running = false;
  
  // Calculadora
  final IProfileCompletenessCalculator _vendorCalculator = VendorProfileCompletenessCalculator();

  /// API principal: tenta exibir o prompt.
  /// [context] precisa ter Navigator válido.
  Future<void> maybeShow({
    required BuildContext context,
    String? userId,
  }) async {
    if (_running) return; // evita corrida
    _running = true;
    try {
      // 1. Busca usuário atual
      final currentUserId = userId ?? AppState.currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        AppLogger.debug('No current user, skipping prompt', tag: _tag);
        return;
      }
      
      final currentUser = SessionManager.instance.currentUser;
      if (currentUser == null) {
        AppLogger.debug('User not loaded, skipping prompt', tag: _tag);
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // 2. Checa dismiss definitivo
      if (prefs.getBool('$_prefsDismissKeyPrefix$currentUserId') ?? false) {
        AppLogger.debug('User dismissed permanently', tag: _tag);
        return;
      }

      // 3. Checa cooldown (último show)
      final lastTs = prefs.getInt('$_prefsCooldownKeyPrefix$currentUserId');
      if (lastTs != null) {
        final last = DateTime.fromMillisecondsSinceEpoch(lastTs);
        if (DateTime.now().difference(last) < cooldown) {
          AppLogger.debug('Still in cooldown period', tag: _tag);
          return; // ainda em cooldown
        }
      }

      // 4. Calcula completeness
      final pct = _vendorCalculator.calculate(currentUser);
      AppLogger.info('Calculated completeness: $pct%', tag: _tag);
      
      if (pct >= threshold) {
        AppLogger.debug('Profile already complete ($pct%), skipping prompt', tag: _tag);
        return; // já completo
      }

      if (!context.mounted) return;

      // 5. Exibe bottom sheet
      final i18n = AppLocalizations.of(context);
      AppLogger.info('Showing completeness dialog ($pct%)', tag: _tag);
      
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return ProfileCompletenessDialog(
            photoUrl: currentUser.userProfilePhoto,
            percentage: pct,
            title: i18n.translate('complete_your_profile'),
            subtitle: i18n.translate('profile_completeness_percentage_subtitle')
                .replaceAll('{percentage}', pct.toString()),
            onDontShow: () async {
              await prefs.setBool('$_prefsDismissKeyPrefix$currentUserId', true);
              AppLogger.info('User dismissed permanently', tag: _tag);
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
            },
            onEditProfile: () async {
              // Marca último show (cooldown começa agora)
              await prefs.setInt(
                '$_prefsCooldownKeyPrefix$currentUserId',
                DateTime.now().millisecondsSinceEpoch,
              );
              AppLogger.info('User clicked edit profile', tag: _tag);
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
              
              // Navegar para tela de edição imediatamente
              if (context.mounted) {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const EditProfileScreen(),
                  ),
                );
              }
            },
          );
        },
      );

      // 6. Marca último show apenas se não houve dismiss definitivo
      final dismissed = prefs.getBool('$_prefsDismissKeyPrefix$currentUserId') ?? false;
      if (!dismissed) {
        await prefs.setInt(
          '$_prefsCooldownKeyPrefix$currentUserId',
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e, stack) {
      AppLogger.error('Error in ProfileCompletenessPromptService', tag: _tag, error: e, stackTrace: stack);
    } finally {
      _running = false;
    }
  }

  /// Método público para calcular o percentual de completude do perfil
  /// Retorna 0-100
  int calculateCompleteness() {
    final currentUser = SessionManager.instance.currentUser;
    if (currentUser == null) return 0;
    
    return _vendorCalculator.calculate(currentUser);
  }
  
  /// Calcula a completude do perfil de forma síncrona
  /// Mantido para compatibilidade com código existente
  int calculateCompletenessSync(user) {
    return _vendorCalculator.calculate(user);
  }
  
  /// Retorna detalhes granulares do cálculo (para debug/logs)
  Map<String, dynamic> getCompletenessDetails() {
    final currentUser = SessionManager.instance.currentUser;
    if (currentUser == null) return {};
    
    return _vendorCalculator.getDetails(currentUser);
  }
}