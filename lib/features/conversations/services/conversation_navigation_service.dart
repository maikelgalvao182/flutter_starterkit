import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Ultra-simplified conversation navigation service
/// TODO: Implementar navegação para chat quando a tela de chat estiver pronta
class ConversationNavigationService {
  const ConversationNavigationService();

  /// Handle conversation tap - navigate to chat
  Future<void> handleConversationTap({
    required BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get user ID from data
      final otherUserId = (data['user_id'] ?? doc?.id ?? '').toString();
      if (otherUserId.isEmpty) return;

      // TODO: Implementar navegação para tela de chat
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(userId: otherUserId)));

      // Mark as read in background after navigation starts
      if (doc != null) {
        _markAsReadInBackground(doc);
      }
    } catch (e) {
      // Ignore navigation errors
      debugPrint('Error navigating to chat: $e');
    }
  }

  /// Background task to mark message as read (non-blocking)
  void _markAsReadInBackground(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    // Use microtask to execute after current frame
    Future.microtask(() {
      doc.reference.update({
        'message_read': true,
        'unread_count': 0,
      }).catchError((e) {
        // Silent fail - not critical for navigation
      });
    });
  }
}
