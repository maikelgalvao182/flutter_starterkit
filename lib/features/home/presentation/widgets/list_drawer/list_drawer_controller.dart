import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Controller para gerenciar estado do ListDrawer
/// 
/// Responsabilidades:
/// - Escutar streams de eventos do usuário (seus eventos criados)
/// 
/// ✅ SINGLETON com ValueNotifiers para evitar rebuilds desnecessários
/// ✅ Cache mantido entre aberturas do drawer
/// 
/// NOTA: A funcionalidade de "eventos próximos" foi REMOVIDA.
/// LocationQueryService agora busca apenas USUÁRIOS (pessoas), não eventos.
/// Para eventos próximos, use o mapa (AppleMapViewModel + EventMapRepository).
class ListDrawerController {
  // Singleton
  static final ListDrawerController _instance = ListDrawerController._internal();
  factory ListDrawerController() => _instance;
  
  ListDrawerController._internal() {
    debugPrint('🎉 ListDrawerController: Singleton criado');
    _initialize();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Estado usando ValueNotifiers (rebuild granular)
  final ValueNotifier<List<QueryDocumentSnapshot<Map<String, dynamic>>>> myEvents = 
      ValueNotifier([]);
  final ValueNotifier<bool> isLoadingMyEvents = ValueNotifier(true);
  final ValueNotifier<String?> error = ValueNotifier(null);

  // Subscriptions
  StreamSubscription<QuerySnapshot>? _myEventsSubscription;

  // Getters convenientes
  bool get hasMyEvents => myEvents.value.isNotEmpty;
  bool get isEmpty => !isLoadingMyEvents.value && myEvents.value.isEmpty;
  String? get currentUserId => _auth.currentUser?.uid;

  /// Inicializa listeners das streams
  void _initialize() {
    final userId = currentUserId;
    
    if (userId == null) {
      error.value = 'Usuário não autenticado';
      isLoadingMyEvents.value = false;
      debugPrint('❌ ListDrawerController: Usuário não autenticado');
      return;
    }

    // Stream: Eventos criados pelo usuário
    _myEventsSubscription = _firestore
        .collection('events')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          _onMyEventsChanged,
          onError: _onMyEventsError,
        );
    
    debugPrint('✅ ListDrawerController: Stream inicializado para userId: ${userId.substring(0, 8)}...');
  }

  /// Handler para mudanças nos eventos do usuário
  void _onMyEventsChanged(QuerySnapshot snapshot) {
    myEvents.value = snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
    isLoadingMyEvents.value = false;
    debugPrint('✅ ListDrawerController: ${myEvents.value.length} eventos do usuário carregados');
  }

  /// Handler para erros nos eventos do usuário
  void _onMyEventsError(dynamic err) {
    error.value = 'Erro ao carregar suas atividades';
    isLoadingMyEvents.value = false;
    debugPrint('❌ ListDrawerController: Erro ao carregar eventos do usuário: $err');
  }

  /// Recarrega os dados
  void refresh() {
    isLoadingMyEvents.value = true;
    error.value = null;
    
    // A stream já vai recarregar automaticamente
    debugPrint('🔄 ListDrawerController: Refresh solicitado');
  }

  void dispose() {
    // Singleton não deve ser disposto
    debugPrint('⚠️ ListDrawerController: dispose() chamado (singleton não será destruído)');
  }
}
