import 'package:flutter/foundation.dart';

class EventInfo {
  final String id;
  final String name;
  final String emoji;

  const EventInfo({
    required this.id,
    required this.name,
    required this.emoji,
  });

  EventInfo copyWith({
    String? name,
    String? emoji,
  }) {
    return EventInfo(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
    );
  }
}

class EventStore {
  static final EventStore instance = EventStore._();
  EventStore._();

  final Map<String, ValueNotifier<EventInfo?>> _events = {};

  ValueNotifier<EventInfo?> getEventNotifier(String eventId) {
    if (!_events.containsKey(eventId)) {
      _events[eventId] = ValueNotifier<EventInfo?>(null);
    }
    return _events[eventId]!;
  }

  void updateEvent(String eventId, {String? name, String? emoji}) {
    final notifier = getEventNotifier(eventId);
    final current = notifier.value;
    
    if (current == null) {
      if (name != null && emoji != null) {
        notifier.value = EventInfo(id: eventId, name: name, emoji: emoji);
      }
    } else {
      notifier.value = current.copyWith(
        name: name,
        emoji: emoji,
      );
    }
  }
  
  /// Inicializa ou atualiza dados do evento se fornecidos
  void setEventData(String eventId, String name, String emoji) {
    final notifier = getEventNotifier(eventId);
    // Só atualiza se for diferente para evitar notificações desnecessárias
    if (notifier.value?.name != name || notifier.value?.emoji != emoji) {
      notifier.value = EventInfo(id: eventId, name: name, emoji: emoji);
    }
  }
}
