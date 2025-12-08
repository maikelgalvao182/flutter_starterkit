import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:partiu/screens/chat/chat_screen_refactored.dart';
import 'package:partiu/core/models/user.dart' as app_models;
import 'package:partiu/core/services/block_service.dart';
import 'package:partiu/shared/services/toast_service.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Ultra-simplified conversation navigation service
class ConversationNavigationService {
  const ConversationNavigationService();

  /// Handle conversation tap - navigate to chat
  Future<void> handleConversationTap({
    required BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
    required Map<String, dynamic> data,
    String? conversationId,
  }) async {
    try {
      // 1. Verificar se é chat de evento
      final isEventChat = data['is_event_chat'] == true;
      final eventId = data['event_id'] as String?;
      
      // Get user ID from data
      final otherUserId = (data['user_id'] ?? doc?.id ?? '').toString();
      if (otherUserId.isEmpty) return;

      // Verificar se usuário está bloqueado
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (currentUserId.isNotEmpty && 
          BlockService().isBlockedCached(currentUserId, otherUserId)) {
        final i18n = AppLocalizations.of(context);
        ToastService.showWarning(
          context: context,
          title: i18n?.translate('user_blocked_cannot_message') ?? 
          'Você não pode enviar mensagens para este usuário',
        );
        return;
      }

      // Create user object
      final user = _createUserFromConversationData(data, otherUserId);

      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (_) => ChatScreenRefactored(
            user: user,
            isEvent: isEventChat,
            eventId: eventId,
          )
        )
      );

      // Mark as read in background after navigation starts
      final id = conversationId ?? doc?.id;
      if (id != null) {
        _markAsReadInBackground(id, doc);
      }
    } catch (e) {
      // Ignore navigation errors
      debugPrint('Error navigating to chat: $e');
    }
  }

  /// Create user object from conversation data to avoid async fetch
  app_models.User _createUserFromConversationData(Map<String, dynamic> data, String userId) {
    // 🔍 DEBUG: Log dos dados recebidos
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔍 _createUserFromConversationData:');
    debugPrint('   - userId: "$userId"');
    debugPrint('   - is_event_chat: ${data['is_event_chat']}');
    debugPrint('   - event_id: ${data['event_id']}');
    debugPrint('   - fullname: ${data['fullname']}');
    debugPrint('   - user_profile_photo: ${data['user_profile_photo']}');
    debugPrint('   - data keys: ${data.keys.toList()}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Para chats de eventos, os dados já vêm corretos do backend
    // Backend salva como: fullname (activityText) e user_profile_photo (emoji)
    final userName = data['fullname'] ?? 'Unknown User';
    final userPhoto = data['user_profile_photo'] ?? '';
    
    debugPrint('✅ User criado: userName="$userName", userPhoto="$userPhoto"');
    
    // ✅ CORRIGIDO: Usar campos corretos do SessionManager/User model
    // Seguindo o padrão de: sessionManager._userToMap() e User.fromDocument()
    return app_models.User.fromDocument({
      'userId': userId,              // ✅ userId (não user_id)
      'fullName': userName,          // ✅ fullName (não fullname)
      'profilePhotoUrl': userPhoto,  // ✅ profilePhotoUrl (não user_profile_photo)
      'gender': '',
      'birthDay': 1,
      'birthMonth': 1,
      'birthYear': 2000,
      'jobTitle': '',
      'bio': '',
      'country': '',
      'locality': '',
      'latitude': 0.0,
      'longitude': 0.0,
      'status': 'active',
      'level': '',
      'isVerified': false,
      'registrationDate': DateTime.now().toIso8601String(),
      'lastLoginDate': DateTime.now().toIso8601String(),
      'totalLikes': 0,
      'totalVisits': 0,
      'isOnline': false,
    });
  }

  /// Background task to mark message as read (non-blocking)
  void _markAsReadInBackground(
      String conversationId, QueryDocumentSnapshot<Map<String, dynamic>>? doc) {
    // Use microtask to execute after current frame
    Future.microtask(() {
      try {
        if (doc != null) {
          doc.reference.update({
            'message_read': true,
            'unread_count': 0,
          });
        } else {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            FirebaseFirestore.instance
                .collection('Connections')
                .doc(userId)
                .collection('Conversations')
                .doc(conversationId)
                .update({
              'message_read': true,
              'unread_count': 0,
            });
          }
        }
      } catch (_) {
        // Silent fail - not critical for navigation
      }
    });
  }
}