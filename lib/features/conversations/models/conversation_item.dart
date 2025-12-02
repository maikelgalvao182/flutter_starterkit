class ConversationItem {
  final String id; // other userId or conversationId
  final String userId;
  final String userFullname;
  final String? userPhotoUrl;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isRead;

  ConversationItem({
    required this.id,
    required this.userId,
    required this.userFullname,
    this.userPhotoUrl,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isRead = true,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value);
      }
      if (value is num) {
        final n = value.toDouble();
        // Heurística: > 10^12 → millis, senão segundos
        final millis = n > 1000000000000 ? n.toInt() : (n * 1000).toInt();
        return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
      }
      if (value is Map) {
        final seconds = value['seconds'] ?? value['_seconds'];
        final nanos = value['nanoseconds'] ?? value['_nanoseconds'] ?? 0;
        if (seconds is num) {
          final millis =
              (seconds * 1000).toInt() + ((nanos is num ? nanos : 0) ~/ 1000000);
          return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
        }
      }
      return null;
    }

    final rawTs = json['lastMessageAt'] ??
        json['last_message_timestamp'] ??
        json['last_message_at'] ??
        json['timestamp'];
    final parsedTs = parseTimestamp(rawTs);

    // Resolve IDs and name from multiple possible keys
    final id = (json['id'] ?? json['conversationId'] ?? json['userId'] ?? '')
        .toString();
    final userId = (json['userId'] ?? json['other_user_id'] ?? json['id'] ?? '')
        .toString();
    final userFullname =
        (json['userFullname'] ?? json['other_user_name'] ?? '').toString();

    // Resolve last message text from multiple fields
    final lastMessage = (json['lastMessage'] ??
            json['last_message_text'] ??
            json['message_text'] ??
            json['lastMessageText'] ??
            json['last_message'] ??
            '')
        .toString();

    // Resolve message type from multiple fields
    final lastMessageType = (json['lastMessageType'] ??
            json['last_message_type'] ??
            json['message_type'])
        ?.toString();

    // Resolve unread information
    final unreadCountJson =
        (json['unreadCount'] ?? json['unread_count']) as num?;
    final unreadCount = unreadCountJson?.toInt() ?? 0;
    final readFlag = json['isRead'] ?? json['message_read'];
    final isRead = (readFlag is bool)
        ? readFlag
        : unreadCount == 0; // fallback: any unreadCount > 0 => not read

    return ConversationItem(
      id: id,
      userId: userId,
      userFullname: userFullname,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      lastMessage: lastMessage.isNotEmpty ? lastMessage : null,
      lastMessageType: lastMessageType,
      lastMessageAt: parsedTs,
      unreadCount: unreadCount,
      isRead: isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userFullname': userFullname,
      'userPhotoUrl': userPhotoUrl,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'isRead': isRead,
    };
  }
}
