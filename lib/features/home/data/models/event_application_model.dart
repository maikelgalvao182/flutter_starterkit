import 'package:cloud_firestore/cloud_firestore.dart';

/// Status da aplicação para um evento
enum ApplicationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  autoApproved('autoApproved');

  const ApplicationStatus(this.value);
  final String value;

  static ApplicationStatus fromString(String value) {
    return ApplicationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ApplicationStatus.pending,
    );
  }
}

/// Modelo de aplicação de usuário para um evento
class EventApplicationModel {
  final String id;
  final String eventId;
  final String userId;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? decisionAt;

  const EventApplicationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.appliedAt,
    this.decisionAt,
  });

  /// Cria instância a partir de documento Firestore
  factory EventApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EventApplicationModel(
      id: doc.id,
      eventId: data['eventId'] as String,
      userId: data['userId'] as String,
      status: ApplicationStatus.fromString(data['status'] as String),
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      decisionAt: data['decisionAt'] != null 
          ? (data['decisionAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'status': status.value,
      'appliedAt': Timestamp.fromDate(appliedAt),
      if (decisionAt != null) 'decisionAt': Timestamp.fromDate(decisionAt!),
    };
  }

  /// Verifica se a aplicação foi aprovada (automática ou manualmente)
  bool get isApproved => 
      status == ApplicationStatus.approved || 
      status == ApplicationStatus.autoApproved;

  /// Verifica se está pendente
  bool get isPending => status == ApplicationStatus.pending;

  /// Verifica se foi rejeitada
  bool get isRejected => status == ApplicationStatus.rejected;
}
