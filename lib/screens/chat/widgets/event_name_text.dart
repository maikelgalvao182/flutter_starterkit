import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/features/conversations/utils/conversation_styles.dart';
import 'package:partiu/features/events/state/event_store.dart';
import 'package:partiu/screens/chat/controllers/chat_app_bar_controller.dart';
import 'package:partiu/screens/chat/services/chat_service.dart';

/// Nome do evento
class EventNameText extends StatelessWidget {
  const EventNameText({
    required this.user,
    required this.chatService,
    this.controller,
    super.key,
  });

  final User user;
  final ChatService chatService;
  final ChatAppBarController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller != null && controller!.isEvent) {
      return ValueListenableBuilder<EventInfo?>(
        valueListenable: EventStore.instance.getEventNotifier(controller!.eventId),
        builder: (context, eventInfo, _) {
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: chatService.getConversationSummary(user.userId),
            builder: (context, snap) {
              String eventName = eventInfo?.name ?? 'Evento';
              
              if (eventInfo == null && snap.hasData && snap.data!.data() != null) {
                final data = snap.data!.data()!;
                eventName = data['activityText'] ?? eventName;
              }
              return ConversationStyles.buildEventNameText(name: eventName);
            },
          );
        },
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: chatService.getConversationSummary(user.userId),
      builder: (context, snap) {
        String eventName = 'Evento';
        if (snap.hasData && snap.data!.data() != null) {
          final data = snap.data!.data()!;
          eventName = data['activityText'] ?? 'Evento';
        }
        return ConversationStyles.buildEventNameText(name: eventName);
      },
    );
  }
}
