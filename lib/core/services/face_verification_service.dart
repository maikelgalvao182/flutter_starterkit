import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/models/face_verification.dart';
import 'package:partiu/core/utils/app_logger.dart';

/// Serviço para gerenciar verificação de identidade via Didit
/// 
/// Responsabilidades:
/// - Salvar dados de verificação no Firestore
/// - Atualizar status de verificação do usuário
/// - Buscar dados de verificação existentes
/// - Validar verificação de identidade
class FaceVerificationService {
  FaceVerificationService._();
  
  static final FaceVerificationService _instance = FaceVerificationService._();
  static FaceVerificationService get instance => _instance;
  
  static const String _tag = 'FaceVerificationService';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Salva dados de verificação de identidade no Firestore
  /// 
  /// Atualiza:
  /// 1. Documento na coleção FaceVerifications
  /// 2. Campo user_is_verified no documento do usuário
  /// 
  /// Parâmetros:
  /// - facialId: ID único da verificação (do Didit)
  /// - userInfo: Dados adicionais da verificação
  Future<bool> saveVerification({
    required String facialId,
    required Map<String, dynamic> userInfo,
  }) async {
    try {
      final userId = AppState.currentUserId;
      if (userId == null || userId.isEmpty) {
        AppLogger.error('UserId não disponível para salvar verificação', tag: _tag);
        return false;
      }

      final verification = FaceVerification(
        userId: userId,
        facialId: facialId,
        verifiedAt: DateTime.now(),
        status: 'verified',
        gender: userInfo['details']?['gender'] as String? ?? 
                userInfo['gender'] as String?,
        age: userInfo['details']?['age'] as int? ?? 
             userInfo['age'] as int?,
        details: {
          ...userInfo,
          'verification_type': 'didit',
          'verification_date': DateTime.now().toIso8601String(),
        },
      );

      // Salva na coleção FaceVerifications
      await _firestore
          .collection('FaceVerifications')
          .doc(userId)
          .set(verification.toFirestore());

      // Atualiza flag de verificação no usuário
      await _firestore
          .collection('Users')
          .doc(userId)
          .update({
        'user_is_verified': true,
        'verified_at': FieldValue.serverTimestamp(),
        'facial_id': facialId,
        'verification_type': 'didit',
      });

      AppLogger.success('Verificação de identidade salva com sucesso (Didit)', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao salvar verificação de identidade: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Busca dados de verificação de um usuário
  Future<FaceVerification?> getVerification(String userId) async {
    try {
      final doc = await _firestore
          .collection('FaceVerifications')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return FaceVerification.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao buscar verificação: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Verifica se o usuário atual está verificado
  Future<bool> isUserVerified([String? userId]) async {
    try {
      final uid = userId ?? AppState.currentUserId;
      if (uid == null || uid.isEmpty) return false;

      final doc = await _firestore
          .collection('Users')
          .doc(uid)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      return data?['user_is_verified'] == true;
    } catch (e) {
      AppLogger.error('Erro ao verificar status: $e', tag: _tag);
      return false;
    }
  }

  /// Stream para observar mudanças no status de verificação
  Stream<bool> watchVerificationStatus(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>?;
      return data?['user_is_verified'] == true;
    }).handleError((error) {
      AppLogger.error('Erro no stream de verificação: $error', tag: _tag);
      return false;
    });
  }

  /// Remove verificação (admin only)
  Future<bool> removeVerification(String userId) async {
    try {
      // Remove da coleção FaceVerifications
      await _firestore
          .collection('FaceVerifications')
          .doc(userId)
          .delete();

      // Remove flag do usuário
      await _firestore
          .collection('Users')
          .doc(userId)
          .update({
        'user_is_verified': false,
        'verified_at': FieldValue.delete(),
        'facial_id': FieldValue.delete(),
      });

      AppLogger.info('Verificação removida', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao remover verificação: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Valida consistência dos dados de verificação
  /// 
  /// Verifica se:
  /// - Existe documento na coleção FaceVerifications
  /// - Flag user_is_verified está true
  /// - facialId corresponde
  Future<bool> validateVerification(String userId) async {
    try {
      final verification = await getVerification(userId);
      if (verification == null || !verification.isVerified) {
        return false;
      }

      final userDoc = await _firestore
          .collection('Users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>?;
      final isVerified = userData?['user_is_verified'] == true;
      final facialId = userData?['facial_id'] as String?;

      return isVerified && facialId == verification.facialId;
    } catch (e) {
      AppLogger.error('Erro ao validar verificação: $e', tag: _tag);
      return false;
    }
  }
}
