import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/models/didit_session.dart';
import 'package:partiu/core/utils/app_logger.dart';

/// Serviço para gerenciar verificação via Didit
/// 
/// Responsabilidades:
/// - Criar sessões de verificação
/// - Buscar configurações da API do Didit
/// - Gerenciar callbacks de verificação
/// - Salvar resultados de verificação
class DiditVerificationService {
  DiditVerificationService._();
  
  static final DiditVerificationService _instance = DiditVerificationService._();
  static DiditVerificationService get instance => _instance;
  
  static const String _tag = 'DiditVerificationService';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Cache das configurações do Didit
  Map<String, dynamic>? _cachedConfig;
  
  /// Busca as configurações do Didit do Firestore (com cache)
  /// Localização: AppInfo > didio
  /// 
  /// Estrutura esperada:
  /// {
  ///   "api_key": "sua-api-key",
  ///   "app_id": "seu-app-id",
  ///   "callback_url": "https://sua-app.com/verification/callback" (opcional)
  /// }
  Future<Map<String, dynamic>?> getDiditConfig() async {
    // Retorna do cache se disponível
    if (_cachedConfig != null) {
      return _cachedConfig;
    }
    
    try {
      final doc = await _firestore
          .collection('AppInfo')
          .doc('didio')
          .get();
      
      if (!doc.exists) {
        AppLogger.error('Documento didio não encontrado em AppInfo', tag: _tag);
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>?;
      
      if (data == null || data.isEmpty) {
        AppLogger.error('Configurações do Didit não encontradas', tag: _tag);
        return null;
      }
      
      // Valida campos obrigatórios
      final apiKey = data['api_key'] as String?;
      // Tenta buscar workflow_id primeiro, depois app_id como fallback
      final workflowId = data['workflow_id'] as String? ?? data['app_id'] as String?;
      
      if (apiKey == null || apiKey.isEmpty) {
        AppLogger.error('API key do Didit não encontrada', tag: _tag);
        return null;
      }
      
      if (workflowId == null || workflowId.isEmpty) {
        AppLogger.error('workflow_id do Didit não encontrado em AppInfo/didio', tag: _tag);
        return null;
      }
      
      // Valida formato do workflow_id (deve ser UUID)
      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      
      if (!uuidPattern.hasMatch(workflowId)) {
        AppLogger.error(
          'workflow_id inválido: "$workflowId" não é um UUID válido',
          tag: _tag,
        );
        return null;
      }
      
      // Cacheia as configurações
      _cachedConfig = data;
      AppLogger.info('Configurações do Didit carregadas com sucesso', tag: _tag);
      
      return data;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao buscar configurações do Didit: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Limpa o cache das configurações (útil para forçar reload)
  void clearConfigCache() {
    _cachedConfig = null;
  }
  
  /// Cria uma nova sessão de verificação no Didit
  /// 
  /// IMPORTANTE: Esta função faz chamada direta à API do Didit.
  /// Em produção, considere implementar isso via Cloud Function
  /// para não expor a API key no app.
  Future<DiditSession?> createVerificationSession({
    String? vendorData,
  }) async {
    try {
      final userId = AppState.currentUserId;
      if (userId == null || userId.isEmpty) {
        AppLogger.error('UserId não disponível para criar sessão', tag: _tag);
        return null;
      }

      // Busca configurações
      final config = await getDiditConfig();
      if (config == null) {
        AppLogger.error('Não foi possível obter configurações do Didit', tag: _tag);
        return null;
      }

      final apiKey = config['api_key'] as String;
      final workflowId = config['workflow_id'] as String? ?? config['app_id'] as String;
      final callbackUrl = config['callback_url'] as String? ?? 
          'https://partiu.app/verification/callback';

      // Cria sessão via API do Didit
      final sessionUri = Uri.parse('https://verification.didit.me/v2/session/');
      final headers = {
        'Content-Type': 'application/json',
        'X-Api-Key': apiKey,
      };

      final body = jsonEncode({
        'workflow_id': workflowId,
        'vendor_data': vendorData ?? userId,
        'callback': callbackUrl,
      });

      AppLogger.info(
        'Criando sessão de verificação no Didit...\n'
        'workflow_id: $workflowId\n'
        'vendor_data: ${vendorData ?? userId}',
        tag: _tag,
      );

      final response = await http.post(sessionUri, headers: headers, body: body);

      AppLogger.info(
        'Resposta da API Didit:\n'
        'Status: ${response.statusCode}\n'
        'Body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final sessionUrl = responseData['url'] as String?;
        final sessionId = responseData['session_id'] as String?; // API retorna 'session_id', não 'id'

        if (sessionUrl == null || sessionId == null) {
          AppLogger.error(
            'Resposta da API do Didit inválida. Dados recebidos:\n'
            'url: $sessionUrl\n'
            'id: $sessionId\n'
            'response completo: $responseData',
            tag: _tag,
          );
          return null;
        }

        // Cria objeto da sessão
        final session = DiditSession(
          sessionId: sessionId,
          userId: userId,
          url: sessionUrl,
          workflowId: workflowId,
          createdAt: DateTime.now(),
          status: 'pending',
          vendorData: vendorData ?? userId,
        );

        // ✅ REMOVIDO: Não salva em DiditSessions - usar estado local
        AppLogger.info('Sessão criada com sucesso: $sessionId', tag: _tag);
        return session;
      } else {
        AppLogger.error(
          'Erro ao criar sessão no Didit: ${response.statusCode} ${response.body}',
          tag: _tag,
        );
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao criar sessão de verificação: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  // ✅ REMOVIDO: getSession - não precisamos mais consultar DiditSessions
  
  // ✅ REMOVIDO: updateSessionStatus - webhook atualiza direto Users + FaceVerifications
  
  /// Método placeholder para compatibilidade (remover se não usado)
  @deprecated
  Future<bool> updateSessionStatus({
    required String sessionId,
    required String status,
    Map<String, dynamic>? result,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'completedAt': Timestamp.now(),
      };
      
      if (result != null) {
        updateData['result'] = result;
      }
      
      await _firestore
          .collection('DiditSessions')
          .doc(sessionId)
          .update(updateData);
      
      AppLogger.info('Status da sessão atualizado: $sessionId -> $status', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao atualizar status da sessão: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
  
  // ✅ REMOVIDO: getUserSessions - histórico pode ser consultado via FaceVerifications
  
  // ✅ REMOVIDO: getPendingSession - estado local no Flutter é suficiente
  
  /// Verifica se usuário já foi verificado (via FaceVerifications)
  Future<bool> isAlreadyVerified(String userId) async {
    try {
      final doc = await _firestore
          .collection('FaceVerifications')
          .doc(userId)
          .get();
      
      return doc.exists && doc.data()?['status'] == 'verified';
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao verificar se usuário já foi verificado: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
  
  /// Stream para observar mudanças em uma sessão
  Stream<DiditSession?> watchSession(String sessionId) {
    return _firestore
        .collection('DiditSessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return DiditSession.fromFirestore(doc);
        });
  }
}
