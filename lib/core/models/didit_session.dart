import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para sessões de verificação do Didit
class DiditSession {
  final String sessionId;
  final String userId;
  final String url;
  final String workflowId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String status; // 'pending', 'completed', 'failed', 'expired'
  final String? vendorData;
  final Map<String, dynamic>? result;

  DiditSession({
    required this.sessionId,
    required this.userId,
    required this.url,
    required this.workflowId,
    required this.createdAt,
    this.completedAt,
    required this.status,
    this.vendorData,
    this.result,
  });

  /// Cria uma instância a partir do Firestore
  factory DiditSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiditSession(
      sessionId: doc.id,
      userId: data['userId'] as String,
      url: data['url'] as String,
      workflowId: data['workflowId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      status: data['status'] as String,
      vendorData: data['vendorData'] as String?,
      result: data['result'] as Map<String, dynamic>?,
    );
  }

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'url': url,
      'workflowId': workflowId,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status,
      'vendorData': vendorData,
      'result': result,
    };
  }

  /// Cria uma cópia com valores alterados
  DiditSession copyWith({
    String? sessionId,
    String? userId,
    String? url,
    String? workflowId,
    DateTime? createdAt,
    DateTime? completedAt,
    String? status,
    String? vendorData,
    Map<String, dynamic>? result,
  }) {
    return DiditSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      url: url ?? this.url,
      workflowId: workflowId ?? this.workflowId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      vendorData: vendorData ?? this.vendorData,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return 'DiditSession(sessionId: $sessionId, userId: $userId, status: $status, url: $url)';
  }
}
