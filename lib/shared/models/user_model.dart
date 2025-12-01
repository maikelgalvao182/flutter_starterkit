import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo simplificado de usuário
class UserModel {
  final String userId;
  final String? fullName;
  final String? email;
  final String? photoUrl;
  final String userType; // 'vendor' ou 'bride'
  
  const UserModel({
    required this.userId,
    this.fullName,
    this.email,
    this.photoUrl,
    this.userType = 'vendor',
  });
  
  factory UserModel.fromFirebaseUser(firebase_auth.User user) {
    return UserModel(
      userId: user.uid,
      fullName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }
  
  /// Cria UserModel a partir de documento Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      fullName: data['fullName'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      userType: data['userType'] as String? ?? 'vendor',
    );
  }
  
  /// Cria UserModel a partir de Map
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      userId: id,
      fullName: map['fullName'] as String?,
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String?,
      userType: map['userType'] as String? ?? 'vendor',
    );
  }
  
  /// Cria uma cópia com campos atualizados
  UserModel copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? photoUrl,
    String? userType,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
    );
  }
  
  // Lista de gêneros
  static List<String> get genders => ['Male', 'Female', 'Other'];
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'userType': userType,
    };
  }
  
  /// Alias para toMap (consistência com fromMap)
  Map<String, dynamic> toJson() => toMap();
  
  // Métodos para OAuth display name
  Future<void> setOAuthDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('oauth_display_name', name);
  }
  
  Future<String?> getOAuthDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('oauth_display_name');
  }
  
  Future<void> clearOAuthDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('oauth_display_name');
  }
}
