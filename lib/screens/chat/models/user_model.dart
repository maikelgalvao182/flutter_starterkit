/// Modelo simplificado de usuário para o chat com otimizações de performance
class UserModel {

  const UserModel({
    required this.id,
    this.name,
    this.photoUrl,
    this.isOnline,
    this.lastLogin,
  });

  /// Criar UserModel a partir de documento Firestore
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime? lastLogin;
    try {
      final lastLoginField = data['user_last_login'];
      if (lastLoginField != null) {
        lastLogin = (lastLoginField as dynamic).toDate();
      }
    } catch (e) {
      // Se houver erro ao converter timestamp, deixar null
      lastLogin = null;
    }

    // ⚠️ FILTRAR URLs do Google OAuth (dados legados)
    var rawPhotoUrl = data['photoUrl'] as String?;
    if (rawPhotoUrl != null && 
        (rawPhotoUrl.contains('googleusercontent.com') || 
         rawPhotoUrl.contains('lh3.google'))) {
      rawPhotoUrl = null;
    }

    return UserModel(
      id: id,
      name: data['fullName'] as String? ?? data['fullname'] as String?, // ✅ Priorizar fullName, fallback fullname
      photoUrl: rawPhotoUrl,
      isOnline: data['user_is_online'] as bool?,
      lastLogin: lastLogin,
    );
  }
  final String id;
  final String? name;
  final String? photoUrl;
  final bool? isOnline;
  final DateTime? lastLogin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
