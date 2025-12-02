/// Interface para repositório de perfil de usuário
/// Define contrato para operações de profile com Firestore
abstract class IProfileRepository {
  /// Busca dados do perfil para edição
  Future<Map<String, dynamic>?> fetchProfileData(String userId);
  
  /// Salva alterações no perfil do usuário
  Future<void> updateProfile(String userId, Map<String, dynamic> profileData);
  
  /// Atualiza apenas a URL da foto de perfil
  Future<void> updateProfilePhoto(String userId, String photoUrl);
  
  /// Atualiza localização do usuário
  Future<void> updateLocation(
    String userId, {
    required Map<String, dynamic> location,
    required String address,
  });
}
