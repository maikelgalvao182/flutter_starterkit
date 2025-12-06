import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/utils/app_logger.dart';

/// API REST para operações de Location
/// 
/// NOTA: Versão simplificada usando Firestore direto
/// TODO: Migrar para REST API quando backend estiver pronto
class LocationApiRest {
  LocationApiRest({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Atualiza a localização do usuário
  /// 
  /// Salva em Users collection com geoFirePoint para queries espaciais
  Future<LocationApiResponse> updateLocation({
    required String userId,
    required double latitude,
    required double longitude,
    required String country,
    required String locality,
    required String state,
    String? formattedAddress,
  }) async {
    if (userId.isEmpty) {
      return LocationApiResponse(
        success: false,
        error: LocationApiError(
          code: 'invalid-argument',
          message: 'userId cannot be empty',
        ),
      );
    }

    try {
      final requestData = {
        'latitude': latitude,
        'longitude': longitude,
        'country': country,
        'locality': locality,
        'state': state,
      };

      AppLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', tag: 'LocationApiRest');
      AppLogger.info('📤 REQUEST BODY:', tag: 'LocationApiRest');
      AppLogger.info('   Path: Users/$userId', tag: 'LocationApiRest');
      AppLogger.info('   Data: $requestData', tag: 'LocationApiRest');
      AppLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', tag: 'LocationApiRest');

      // Atualiza documento do usuário com latitude e longitude diretas
      final updateData = {
        'latitude': latitude,
        'longitude': longitude,
        'country': country,
        'locality': locality,
        'state': state,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (formattedAddress != null && formattedAddress.isNotEmpty) {
        updateData['formattedAddress'] = formattedAddress;
      }
      
      await _firestore.collection('Users').doc(userId).update(updateData);

      AppLogger.success('✅ SUCCESS', tag: 'LocationApiRest');

      return LocationApiResponse(
        success: true,
        data: {'message': 'Location updated successfully'},
      );
    } catch (e) {
      AppLogger.error('❌ ERROR: $e', tag: 'LocationApiRest');

      return LocationApiResponse(
        success: false,
        error: LocationApiError(
          code: 'update-location-error',
          message: 'Failed to update location: $e',
        ),
      );
    }
  }


}

/// Response da API de localização
class LocationApiResponse {
  LocationApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  final bool success;
  final Map<String, dynamic>? data;
  final LocationApiError? error;
}

/// Erro da API de localização
class LocationApiError {
  LocationApiError({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}
