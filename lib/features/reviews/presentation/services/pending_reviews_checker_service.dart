import 'package:flutter/material.dart';
import 'package:partiu/features/reviews/data/repositories/review_repository.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';
import 'package:partiu/features/reviews/presentation/dialogs/review_dialog.dart';
import 'package:partiu/core/services/toast_service.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Serviço que verifica e exibe automaticamente PendingReviews
/// quando o usuário abre o app
class PendingReviewsCheckerService {
  static final PendingReviewsCheckerService _instance = 
      PendingReviewsCheckerService._internal();
  
  factory PendingReviewsCheckerService() => _instance;
  
  PendingReviewsCheckerService._internal();

  final ReviewRepository _repository = ReviewRepository();
  
  /// Flag para evitar múltiplas verificações simultâneas
  bool _isChecking = false;
  
  /// Timestamp da última verificação para rate limiting
  DateTime? _lastCheckTime;
  
  /// Duração mínima entre verificações (5 minutos)
  static const Duration _minCheckInterval = Duration(minutes: 5);

  /// Verifica pending reviews e exibe dialog se houver algum pendente
  /// 
  /// Deve ser chamado após login ou quando o app volta ao foreground
  /// 
  /// [forceRefresh]: Se true, ignora rate limiting
  /// 
  /// Retorna: true se mostrou algum dialog, false caso contrário
  Future<bool> checkAndShowPendingReviews(
    BuildContext context, {
    bool forceRefresh = false,
  }) async {
    // Rate limiting: evita verificações muito frequentes (exceto se forceRefresh)
    if (!forceRefresh && _lastCheckTime != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
      if (timeSinceLastCheck < _minCheckInterval) {
        debugPrint(
          '⏭️ [PendingReviewsChecker] Pulando verificação '
          '(última há ${timeSinceLastCheck.inMinutes}min)'
        );
        return false;
      }
    }

    // Evita verificações simultâneas
    if (_isChecking) {
      debugPrint('⏭️ [PendingReviewsChecker] Verificação já em andamento');
      return false;
    }

    _isChecking = true;
    _lastCheckTime = DateTime.now();

    try {
      debugPrint('🔍 [PendingReviewsChecker] Verificando pending reviews...');
      
      final pendingReviews = await _repository.getPendingReviews();
      
      debugPrint('📦 [PendingReviewsChecker] getPendingReviews retornou: ${pendingReviews.length} reviews');
      
      if (pendingReviews.isEmpty) {
        debugPrint('✅ [PendingReviewsChecker] Nenhum review pendente');
        return false;
      }

      debugPrint(
        '📋 [PendingReviewsChecker] Encontrado(s) '
        '${pendingReviews.length} review(s) pendente(s)'
      );

      // Mostra dialog para o primeiro review pendente
      // (após completar, o serviço pode ser chamado novamente)
      debugPrint('🔍 [PendingReviewsChecker] Verificando context.mounted: ${context.mounted}');
      
      if (context.mounted) {
        debugPrint('🎬 [PendingReviewsChecker] Chamando _showReviewDialog...');
        await _showReviewDialog(context, pendingReviews.first);
        return true;
      } else {
        debugPrint('⚠️ [PendingReviewsChecker] Context não está mounted!');
      }

      return false;
    } catch (e, stack) {
      debugPrint('❌ [PendingReviewsChecker] Erro: $e');
      debugPrint('Stack trace: $stack');
      return false;
    } finally {
      _isChecking = false;
    }
  }

  /// Exibe o ReviewDialog para um pending review específico
  Future<void> _showReviewDialog(
    BuildContext context,
    PendingReviewModel pending,
  ) async {
    debugPrint(
      '🎯 [PendingReviewsChecker] Exibindo dialog para avaliar '
      '${pending.revieweeName} (evento: ${pending.eventTitle})'
    );
    
    debugPrint('🔍 [PendingReviewsChecker] PendingReview ID: ${pending.pendingReviewId}, Role: ${pending.reviewerRole}');

    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (dialogContext) => ReviewDialog(
          pendingReview: pending,
        ),
      );

      debugPrint('🔍 [PendingReviewsChecker] Result do dialog: $result');

      if (result == true) {
        debugPrint('✅ [PendingReviewsChecker] Review enviado com sucesso');
        
        // Se houver mais reviews pendentes, pergunta se quer continuar
        if (context.mounted) {
          await _checkForMoreReviews(context);
        }
      } else {
        debugPrint('ℹ️ [PendingReviewsChecker] Review cancelado ou descartado');
      }
    } catch (e, stack) {
      debugPrint('❌ [PendingReviewsChecker] Erro ao mostrar dialog: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  /// Verifica se há mais reviews pendentes após completar um
  Future<void> _checkForMoreReviews(BuildContext context) async {
    try {
      final remainingReviews = await _repository.getPendingReviews();
      
      if (remainingReviews.isEmpty) {
        debugPrint('✅ [PendingReviewsChecker] Todos os reviews concluídos');
        return;
      }

      debugPrint(
        '📋 [PendingReviewsChecker] Ainda há ${remainingReviews.length} '
        'review(s) pendente(s)'
      );

      // Mostra toast informando sobre reviews restantes
      if (context.mounted) {
        final i18n = AppLocalizations.of(context);
        final message = remainingReviews.length == 1
            ? i18n.translate('pending_review_remaining_single')
            : i18n.translate('pending_reviews_remaining').replaceAll('{count}', remainingReviews.length.toString());
        
        ToastService.showInfo(message: message);
        
        // Aguardar um momento antes de mostrar o próximo dialog
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          _showReviewDialog(context, remainingReviews.first);
        }
      }
    } catch (e) {
      debugPrint('❌ [PendingReviewsChecker] Erro ao verificar mais reviews: $e');
    }
  }

  /// Reseta o rate limiting (útil para testes ou forçar verificação)
  void resetRateLimit() {
    _lastCheckTime = null;
    debugPrint('🔄 [PendingReviewsChecker] Rate limit resetado');
  }

  /// Retorna o número de reviews pendentes (sem mostrar dialog)
  Future<int> getPendingReviewsCount() async {
    try {
      return await _repository.getPendingReviewsCount();
    } catch (e) {
      debugPrint('❌ [PendingReviewsChecker] Erro ao contar reviews: $e');
      return 0;
    }
  }
}
