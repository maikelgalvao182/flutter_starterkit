import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/models/user.dart';

/// Evento de mudança em visitas ao perfil
/// 
/// Usado para atualizar lista local sem rebuild completo
abstract class VisitEvent {
  const VisitEvent();
}

/// Evento: Nova visita adicionada
class VisitAdded extends VisitEvent {
  final User visitor;
  final double? rating;

  const VisitAdded({
    required this.visitor,
    this.rating,
  });
}

/// Evento: Visita atualizada (ex: rating mudou)
class VisitUpdated extends VisitEvent {
  final String userId;
  final User? visitor;
  final double? rating;

  const VisitUpdated({
    required this.userId,
    this.visitor,
    this.rating,
  });
}

/// Evento: Visita removida
class VisitRemoved extends VisitEvent {
  final String userId;

  const VisitRemoved({required this.userId});
}

/// Evento: Carregamento inicial completado
class VisitsLoaded extends VisitEvent {
  final List<User> visitors;
  final Map<String, double> ratings;

  const VisitsLoaded({
    required this.visitors,
    required this.ratings,
  });
}

/// Evento: Erro ao processar mudança
class VisitError extends VisitEvent {
  final String message;

  const VisitError({required this.message});
}
