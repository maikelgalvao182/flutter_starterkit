import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/features/home/presentation/viewmodels/apple_map_viewmodel.dart';
import 'package:partiu/features/home/presentation/widgets/event_card/event_card.dart';
import 'package:partiu/features/home/presentation/widgets/event_card/event_card_controller.dart';
import 'package:partiu/screens/chat/chat_screen_refactored.dart';

/// Widget de mapa Apple Maps limpo e performático
/// 
/// Responsabilidades:
/// - Renderizar o Apple Map
/// - Exibir localização do usuário
/// - Exibir markers (delegado ao ViewModel)
/// - Controlar câmera
/// 
/// Toda lógica de negócio foi extraída para:
/// - AppleMapViewModel (orquestração)
/// - EventMarkerService (markers)
/// - UserLocationService (localização)
/// - AvatarService (avatares)
class AppleMapView extends StatefulWidget {
  const AppleMapView({super.key});

  @override
  State<AppleMapView> createState() => AppleMapViewState();
}

class AppleMapViewState extends State<AppleMapView> {
  /// Método público para centralizar no usuário
  void centerOnUser() {
    _moveCameraToUserLocation();
  }
  /// Controller do mapa Apple Maps
  AppleMapController? _mapController;

  /// ViewModel para gerenciar estado e lógica
  late final AppleMapViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AppleMapViewModel(
      onMarkerTap: _onMarkerTap,
    );
    _initializeMap();
  }

  /// Inicializa o mapa e carrega dados
  Future<void> _initializeMap() async {
    await _viewModel.initialize();
  }

  /// Callback quando o mapa é criado
  void _onMapCreated(AppleMapController controller) {
    _mapController = controller;

    // Mover câmera e carregar eventos
    _moveCameraToUserLocation();

    // Carregar eventos após posicionar câmera
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _viewModel.loadNearbyEvents();
      }
    });
  }

  /// Move a câmera para a localização do usuário
  Future<void> _moveCameraToUserLocation() async {
    final result = await _viewModel.getUserLocation();

    // Exibir mensagem de erro se houver
    if (result.hasError && mounted) {
      _showMessage(result.errorMessage!);
    }

    // Mover câmera
    await _moveCameraTo(
      result.location.latitude,
      result.location.longitude,
      zoom: 15.0,
    );
  }

  /// Move a câmera para uma coordenada específica
  Future<void> _moveCameraTo(
    double lat,
    double lng, {
    double zoom = 14.0,
  }) async {
    if (_mapController == null) return;

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, lng),
            zoom: zoom,
          ),
        ),
      );
    } catch (e) {
      // Falha silenciosa - câmera continua onde está
    }
  }

  /// Exibe mensagem para o usuário
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Callback quando usuário toca em um marker
  void _onMarkerTap(String eventId) async {
    // Criar controller e carregar dados ANTES de abrir o dialog
    final controller = EventCardController(eventId: eventId);
    
    try {
      // Aguardar o carregamento completo dos dados
      await controller.load();
      
      // Verificar se os dados foram carregados com sucesso
      if (!controller.hasData) {
        if (mounted) {
          _showMessage(controller.error ?? 'Erro ao carregar evento');
        }
        return;
      }
      
      // Agora sim, abrir o dialog com todos os dados prontos
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        builder: (context) => EventCard(
          controller: controller,
          onActionPressed: () async {
            // Capturar o navigator antes de fechar o modal
            final navigator = Navigator.of(context);
            
            // Fechar o card
            navigator.pop();
            
            // Se for o criador ou estiver aprovado, navegar para o chat
            if (controller.isCreator || controller.isApproved) {
              // Buscar dados do evento para pegar o nome
              final eventDoc = await FirebaseFirestore.instance
                  .collection('events')
                  .doc(eventId)
                  .get();
              
              if (!eventDoc.exists) return;
              
              final eventData = eventDoc.data()!;
              final eventName = eventData['activityText'] as String? ?? 'Evento';
              final emoji = eventData['emoji'] as String? ?? '🎉';
              
              // ✅ CORRIGIDO: Usar event_${eventId} (igual ao backend e conversation_navigation_service)
              // Criar User com dados do evento usando campos corretos do SessionManager
              final chatUser = User.fromDocument({
                'userId': 'event_$eventId',  // ✅ Prefixo event_ para consistência
                'fullName': eventName,
                'profilePhotoUrl': emoji,
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
              
              // Usar o navigator capturado anteriormente
              navigator.push(
                MaterialPageRoute(
                  builder: (context) => ChatScreenRefactored(
                    user: chatUser,
                    isEvent: true,
                    eventId: eventId,
                  ),
                ),
              );
            }
            
            controller.dispose();
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage('Erro ao carregar evento');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Widget limpo - apenas UI
    // Toda lógica delegada ao ViewModel
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return AppleMap(
          // Callback de criação
          onMapCreated: _onMapCreated,

          // Posição inicial (São Paulo)
          initialCameraPosition: const CameraPosition(
            target: LatLng(-23.5505, -46.6333),
            zoom: 12.0,
          ),

          // Markers fornecidos pelo ViewModel
          annotations: _viewModel.eventMarkers,

          // Configurações do mapa
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          mapType: MapType.standard,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
        );
      },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _mapController = null;
    super.dispose();
  }
}
