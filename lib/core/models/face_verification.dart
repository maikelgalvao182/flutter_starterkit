import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para armazenar dados de verificação de identidade via Didit
class FaceVerification {
  const FaceVerification({
    required this.userId,
    required this.facialId,
    required this.verifiedAt,
    required this.status,
    this.gender,
    this.age,
    this.details,
  });

  /// ID do usuário no app
  final String userId;
  
  /// ID único da verificação gerado pelo Didit
  final String facialId;
  
  /// Data/hora da verificação
  final DateTime verifiedAt;
  
  /// Status da verificação: 'verified', 'pending', 'rejected'
  final String status;
  
  /// Gênero estimado (opcional)
  final String? gender;
  
  /// Idade aproximada (opcional)
  final int? age;
  
  /// Detalhes adicionais da verificação
  final Map<String, dynamic>? details;

  /// Cria FaceVerification a partir de documento Firestore
  factory FaceVerification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FaceVerification(
      userId: data['userId'] as String? ?? '',
      facialId: data['facialId'] as String? ?? '',
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'pending',
      gender: data['gender'] as String?,
      age: data['age'] as int?,
      details: data['details'] as Map<String, dynamic>?,
    );
  }

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'facialId': facialId,
      'verifiedAt': Timestamp.fromDate(verifiedAt),
      'status': status,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (details != null) 'details': details,
    };
  }

  /// Verifica se a verificação é válida e aprovada
  bool get isVerified => status == 'verified';

  /// Cria cópia com campos atualizados
  FaceVerification copyWith({
    String? userId,
    String? facialId,
    DateTime? verifiedAt,
    String? status,
    String? gender,
    int? age,
    Map<String, dynamic>? details,
  }) {
    return FaceVerification(
      userId: userId ?? this.userId,
      facialId: facialId ?? this.facialId,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      status: status ?? this.status,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      details: details ?? this.details,
    );
  }
}
