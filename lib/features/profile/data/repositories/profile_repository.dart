import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/features/profile/domain/repositories/profile_repository_interface.dart';

/// Repositório de perfil que acessa Firestore diretamente
/// Sem camada de API - integração direta
/// 
/// Responsabilidades:
/// - Buscar dados de perfil do Firestore
/// - Atualizar perfil do usuário
/// - Gerenciar foto de perfil
/// - Atualizar localização
class ProfileRepository implements IProfileRepository {
  final FirebaseFirestore _firestore;
  
  ProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  static const String _usersCollection = 'Users';
  static const String _tag = 'ProfileRepository';
  
  @override
  Future<Map<String, dynamic>?> fetchProfileData(String userId) async {
    try {
      AppLogger.info('Fetching profile data for user: $userId', tag: _tag);
      
      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (!docSnapshot.exists) {
        AppLogger.warning('Profile not found for user: $userId', tag: _tag);
        return null;
      }
      
      final data = docSnapshot.data();
      AppLogger.info('Profile data fetched successfully', tag: _tag);
      return data;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching profile data: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  @override
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      AppLogger.info('Updating profile for user: $userId', tag: _tag);
      
      // Remove campos nulos para evitar sobrescrever dados existentes
      final cleanedData = Map<String, dynamic>.from(profileData)
        ..removeWhere((key, value) => value == null);
      
      // Adiciona timestamp de atualização
      cleanedData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(cleanedData);
      
      AppLogger.info('Profile updated successfully', tag: _tag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating profile: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  @override
  Future<void> updateProfilePhoto(String userId, String photoUrl) async {
    try {
      AppLogger.info('Updating profile photo for user: $userId', tag: _tag);
      
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
            'userProfilePhoto': photoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      AppLogger.info('Profile photo updated successfully', tag: _tag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating profile photo: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  @override
  Future<void> updateLocation(
    String userId, {
    required Map<String, dynamic> location,
    required String address,
  }) async {
    try {
      AppLogger.info('Updating location for user: $userId', tag: _tag);
      
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
            'userGeoPoint': location,
            'locality': address,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      AppLogger.info('Location updated successfully', tag: _tag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating location: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
