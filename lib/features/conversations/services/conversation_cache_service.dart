import 'package:flutter/material.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/features/conversations/services/conversation_data_processor.dart';

/// Config for notifier updates
class _NotifierConfig {
  _NotifierConfig({required this.i18n, required this.isVipEffective});
  final AppLocalizations i18n;
  final bool isVipEffective;
}

/// Service responsável por gerenciar cache de dados de conversas
/// Evita reprocessamento desnecessário e melhora performance
class ConversationCacheService {
  // Singleton pattern
  static final ConversationCacheService _instance =
      ConversationCacheService._internal();
  factory ConversationCacheService() => _instance;
  ConversationCacheService._internal();

  // Cache for processed conversation display data
  final Map<String, ConversationDisplayData> _displayDataCache = {};

  // Cache for in-flight futures to avoid creating new Future each rebuild (prevents FutureBuilder flicker)
  final Map<String, Future<ConversationDisplayData>>
      _displayDataFutureCache = {};

  // Fine-grained notifiers per conversation (key includes gating + locale) to avoid rebuilding entire list
  final Map<String, ValueNotifier<ConversationDisplayData>>
      _displayDataNotifiers = {};

  // Store i18n and isVipEffective for each notifier key to enable updates
  final Map<String, _NotifierConfig> _notifierConfig = {};

  /// Gera chave única para cache baseada em doc, VIP status e locale
  String _getCacheKey({
    required String docId,
    required bool isVipEffective,
    required AppLocalizations i18n,
  }) {
    return '${docId}_${isVipEffective}_${i18n.translate('lang')}';
  }

  /// Get cached or compute conversation display data
  Future<ConversationDisplayData> getDisplayData({
    required String conversationId,
    required Map<String, dynamic> data,
    required bool isVipEffective,
    required AppLocalizations i18n,
  }) async {
    final cacheKey = _getCacheKey(
      docId: conversationId,
      isVipEffective: isVipEffective,
      i18n: i18n,
    );

    if (_displayDataCache.containsKey(cacheKey)) {
      return _displayDataCache[cacheKey]!;
    }

    final displayData =
        await ConversationDataProcessor.processConversationData(
      data: data,
      isVipEffective: isVipEffective,
      i18n: i18n,
    );

    _displayDataCache[cacheKey] = displayData;
    return displayData;
  }

  /// Return a stable Future for a conversation's display data to avoid
  /// resetting FutureBuilder on every parent list rebuild (which causes flicker)
  Future<ConversationDisplayData> getDisplayDataFuture({
    required String conversationId,
    required Map<String, dynamic> data,
    required bool isVipEffective,
    required AppLocalizations i18n,
  }) {
    final cacheKey = _getCacheKey(
      docId: conversationId,
      isVipEffective: isVipEffective,
      i18n: i18n,
    );

    // If we already have the computed value, return it immediately
    if (_displayDataCache.containsKey(cacheKey)) {
      return Future.value(_displayDataCache[cacheKey]!);
    }

    // Reuse in-flight future if one exists
    final existingFuture = _displayDataFutureCache[cacheKey];
    if (existingFuture != null) {
      return existingFuture;
    }

    // Create and store future
    final future =
        ConversationDataProcessor.processConversationData(
      data: data,
      isVipEffective: isVipEffective,
      i18n: i18n,
    ).then((result) {
      _displayDataCache[cacheKey] = result;
      _displayDataFutureCache.remove(cacheKey); // cleanup
      return result;
    });

    _displayDataFutureCache[cacheKey] = future;
    return future;
  }

  /// Get or create a ValueNotifier for a conversation to enable fine-grained updates
  ValueNotifier<ConversationDisplayData> getDisplayDataNotifier({
    required String conversationId,
    required Map<String, dynamic> data,
    required bool isVipEffective,
    required AppLocalizations i18n,
  }) {
    final cacheKey = _getCacheKey(
      docId: conversationId,
      isVipEffective: isVipEffective,
      i18n: i18n,
    );

    // Return existing notifier
    final existing = _displayDataNotifiers[cacheKey];
    if (existing != null) {
      // Update value if changed to ensure UI reflects latest data (e.g. read status)
      final newData = ConversationDataProcessor.processConversationDataSync(
        data: data,
        isVipEffective: isVipEffective,
        i18n: i18n,
      );
      
      // Check for changes in critical fields
      final current = existing.value;
      if (current.hasUnreadMessage != newData.hasUnreadMessage || 
          current.lastMessage != newData.lastMessage ||
          current.timeAgo != newData.timeAgo ||
          current.displayName != newData.displayName ||
          current.photoUrl != newData.photoUrl) {
         existing.value = newData;
      }
      return existing;
    }

    // Create new notifier with initial sync data
    final initialData =
        ConversationDataProcessor.processConversationDataSync(
      data: data,
      isVipEffective: isVipEffective,
      i18n: i18n,
    );

    final notifier = ValueNotifier<ConversationDisplayData>(initialData);
    _displayDataNotifiers[cacheKey] = notifier;
    _notifierConfig[cacheKey] =
        _NotifierConfig(i18n: i18n, isVipEffective: isVipEffective);

    // Async load full data
    ConversationDataProcessor.processConversationData(
      data: data,
      isVipEffective: isVipEffective,
      i18n: i18n,
    ).then((fullData) {
      if (_displayDataNotifiers.containsKey(cacheKey)) {
        notifier.value = fullData;
        _displayDataCache[cacheKey] = fullData;
      }
    });

    return notifier;
  }

  /// Update notifiers for documents that have changed content
  void updateNotifiersForDocs(
      List<Map<String, dynamic>> docs, List<String> ids) {
    for (var i = 0; i < docs.length; i++) {
      final docId = ids[i];
      final data = docs[i];

      final keysToUpdate =
          _displayDataNotifiers.keys.where((k) => k.startsWith('${docId}_')).toList();
      for (final key in keysToUpdate) {
        final notifier = _displayDataNotifiers[key];
        final config = _notifierConfig[key];
        if (notifier != null && config != null) {
          final newData =
              ConversationDataProcessor.processConversationDataSync(
            data: data,
            isVipEffective: config.isVipEffective,
            i18n: config.i18n,
          );
          final old = notifier.value;
          final merged = ConversationDisplayData(
            photoUrl: newData.photoUrl.isNotEmpty ? newData.photoUrl : old.photoUrl,
            displayName: newData.displayName.isNotEmpty
                ? newData.displayName
                : old.displayName,
            fullName: newData.fullName.isNotEmpty ? newData.fullName : old.fullName,
            maskedName: newData.maskedName.isNotEmpty
                ? newData.maskedName
                : old.maskedName,
            otherUserId: newData.otherUserId.isNotEmpty
                ? newData.otherUserId
                : old.otherUserId,
            lastMessage: newData.lastMessage,
            timeAgo: newData.timeAgo,
            isVip: newData.isVip,
            hasUnreadMessage: newData.hasUnreadMessage,
            messageType: newData.messageType,
            isVerified: newData.isVerified || old.isVerified,
          );
          notifier.value = merged;
        }
      }
    }
  }

  /// Clear all caches
  void clearAll() {
    _displayDataCache.clear();
    _displayDataFutureCache.clear();
    _displayDataNotifiers.clear();
    _notifierConfig.clear();
  }

  /// Dispose all notifiers
  void dispose() {
    for (final notifier in _displayDataNotifiers.values) {
      notifier.dispose();
    }
    clearAll();
  }
}
