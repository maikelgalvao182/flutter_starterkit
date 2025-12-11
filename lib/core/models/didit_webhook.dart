import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para decisão de verificação do Didit
class DiditDecision {
  final String sessionId;
  final int sessionNumber;
  final String sessionUrl;
  final String status;
  final String workflowId;
  final List<String> features;
  final String? vendorData;
  final Map<String, dynamic>? metadata;
  final DiditIdVerification? idVerification;
  final List<DiditReview>? reviews;
  final DateTime createdAt;

  DiditDecision({
    required this.sessionId,
    required this.sessionNumber,
    required this.sessionUrl,
    required this.status,
    required this.workflowId,
    required this.features,
    this.vendorData,
    this.metadata,
    this.idVerification,
    this.reviews,
    required this.createdAt,
  });

  factory DiditDecision.fromJson(Map<String, dynamic> json) {
    return DiditDecision(
      sessionId: json['session_id'] as String,
      sessionNumber: json['session_number'] as int,
      sessionUrl: json['session_url'] as String,
      status: json['status'] as String,
      workflowId: json['workflow_id'] as String,
      features: (json['features'] as List<dynamic>).cast<String>(),
      vendorData: json['vendor_data'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      idVerification: json['id_verification'] != null
          ? DiditIdVerification.fromJson(
              json['id_verification'] as Map<String, dynamic>)
          : null,
      reviews: json['reviews'] != null
          ? (json['reviews'] as List<dynamic>)
              .map((r) => DiditReview.fromJson(r as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'session_number': sessionNumber,
      'session_url': sessionUrl,
      'status': status,
      'workflow_id': workflowId,
      'features': features,
      if (vendorData != null) 'vendor_data': vendorData,
      if (metadata != null) 'metadata': metadata,
      if (idVerification != null) 'id_verification': idVerification!.toJson(),
      if (reviews != null) 'reviews': reviews!.map((r) => r.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Modelo para verificação de ID do Didit
class DiditIdVerification {
  final String status;
  final String? documentType;
  final String? documentNumber;
  final String? personalNumber;
  final String? portraitImage;
  final String? frontImage;
  final String? backImage;
  final String? dateOfBirth;
  final int? age;
  final String? expirationDate;
  final String? dateOfIssue;
  final String? issuingState;
  final String? issuingStateName;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? gender;
  final String? address;
  final String? nationality;
  final List<Map<String, dynamic>>? warnings;

  DiditIdVerification({
    required this.status,
    this.documentType,
    this.documentNumber,
    this.personalNumber,
    this.portraitImage,
    this.frontImage,
    this.backImage,
    this.dateOfBirth,
    this.age,
    this.expirationDate,
    this.dateOfIssue,
    this.issuingState,
    this.issuingStateName,
    this.firstName,
    this.lastName,
    this.fullName,
    this.gender,
    this.address,
    this.nationality,
    this.warnings,
  });

  factory DiditIdVerification.fromJson(Map<String, dynamic> json) {
    return DiditIdVerification(
      status: json['status'] as String,
      documentType: json['document_type'] as String?,
      documentNumber: json['document_number'] as String?,
      personalNumber: json['personal_number'] as String?,
      portraitImage: json['portrait_image'] as String?,
      frontImage: json['front_image'] as String?,
      backImage: json['back_image'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      age: json['age'] as int?,
      expirationDate: json['expiration_date'] as String?,
      dateOfIssue: json['date_of_issue'] as String?,
      issuingState: json['issuing_state'] as String?,
      issuingStateName: json['issuing_state_name'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      fullName: json['full_name'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      nationality: json['nationality'] as String?,
      warnings: json['warnings'] != null
          ? (json['warnings'] as List<dynamic>).cast<Map<String, dynamic>>()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (documentType != null) 'document_type': documentType,
      if (documentNumber != null) 'document_number': documentNumber,
      if (personalNumber != null) 'personal_number': personalNumber,
      if (portraitImage != null) 'portrait_image': portraitImage,
      if (frontImage != null) 'front_image': frontImage,
      if (backImage != null) 'back_image': backImage,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (age != null) 'age': age,
      if (expirationDate != null) 'expiration_date': expirationDate,
      if (dateOfIssue != null) 'date_of_issue': dateOfIssue,
      if (issuingState != null) 'issuing_state': issuingState,
      if (issuingStateName != null) 'issuing_state_name': issuingStateName,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (fullName != null) 'full_name': fullName,
      if (gender != null) 'gender': gender,
      if (address != null) 'address': address,
      if (nationality != null) 'nationality': nationality,
      if (warnings != null) 'warnings': warnings,
    };
  }

  /// Verifica se a verificação foi aprovada
  bool get isApproved => status == 'Approved';
}

/// Modelo para review de verificação
class DiditReview {
  final String user;
  final String newStatus;
  final String? comment;
  final DateTime createdAt;

  DiditReview({
    required this.user,
    required this.newStatus,
    this.comment,
    required this.createdAt,
  });

  factory DiditReview.fromJson(Map<String, dynamic> json) {
    return DiditReview(
      user: json['user'] as String,
      newStatus: json['new_status'] as String,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'new_status': newStatus,
      if (comment != null) 'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Modelo para webhook do Didit
class DiditWebhook {
  final String sessionId;
  final String status;
  final String webhookType;
  final int createdAt;
  final int timestamp;
  final String? workflowId;
  final String? vendorData;
  final Map<String, dynamic>? metadata;
  final DiditDecision? decision;

  DiditWebhook({
    required this.sessionId,
    required this.status,
    required this.webhookType,
    required this.createdAt,
    required this.timestamp,
    this.workflowId,
    this.vendorData,
    this.metadata,
    this.decision,
  });

  factory DiditWebhook.fromJson(Map<String, dynamic> json) {
    return DiditWebhook(
      sessionId: json['session_id'] as String,
      status: json['status'] as String,
      webhookType: json['webhook_type'] as String,
      createdAt: json['created_at'] as int,
      timestamp: json['timestamp'] as int,
      workflowId: json['workflow_id'] as String?,
      vendorData: json['vendor_data'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      decision: json['decision'] != null
          ? DiditDecision.fromJson(json['decision'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'status': status,
      'webhook_type': webhookType,
      'created_at': createdAt,
      'timestamp': timestamp,
      if (workflowId != null) 'workflow_id': workflowId,
      if (vendorData != null) 'vendor_data': vendorData,
      if (metadata != null) 'metadata': metadata,
      if (decision != null) 'decision': decision!.toJson(),
    };
  }

  /// Converte para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      ...toJson(),
      'received_at': FieldValue.serverTimestamp(),
    };
  }

  /// Verifica se é um webhook de status atualizado
  bool get isStatusUpdated => webhookType == 'status.updated';

  /// Verifica se é um webhook de dados atualizados
  bool get isDataUpdated => webhookType == 'data.updated';

  /// Verifica se a verificação foi aprovada
  bool get isApproved => status == 'Approved';

  /// Verifica se a verificação foi recusada
  bool get isDeclined => status == 'Declined';

  /// Verifica se a verificação está em revisão
  bool get isInReview => status == 'In Review';

  /// Verifica se possui decisão
  bool get hasDecision => decision != null;

  /// Verifica se possui verificação de ID aprovada
  bool get hasApprovedIdVerification =>
      decision?.idVerification?.isApproved ?? false;
}
