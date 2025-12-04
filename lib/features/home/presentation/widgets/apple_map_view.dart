import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/features/home/data/models/event_model.dart';
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
  final AppleMapViewModel viewModel;

  const AppleMapView({
    super.key,
    required this.viewModel,
  });

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

  @override
  void initState() {
    super.initState();
    // Configurar callback de tap no ViewModel recebido
    debugPrint('🔴 AppleMapView: Configurando callback onMarkerTap');
    widget.viewModel.onMarkerTap = _onMarkerTap;
    debugPrint('🔴 AppleMapView: Callback configurado? ${widget.viewModel.onMarkerTap != null}');
    
    // Agora que o callback está configurado, carregar eventos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔴 AppleMapView: Carregando eventos APÓS callback configurado');
      widget.viewModel.loadNearbyEvents();
    });
  }

  /// Callback quando o mapa é criado
  void _onMapCreated(AppleMapController controller) {
    _mapController = controller;

    // Mover câmera para localização inicial (já carregada)
    if (widget.viewModel.lastLocation != null) {
      _moveCameraTo(
        widget.viewModel.lastLocation!.latitude,
        widget.viewModel.lastLocation!.longitude,
        zoom: 15.0,
      );
    } else {
      _moveCameraToUserLocation();
    }
  }

  /// Move a câmera para a localização do usuário
  Future<void> _moveCameraToUserLocation() async {
    final result = await widget.viewModel.getUserLocation();

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
  void _onMarkerTap(EventModel event) {
    debugPrint('🔴 AppleMapView._onMarkerTap called for: ${event.id} - ${event.title}');
    
    // Criar controller com evento pré-carregado (evita query Firestore)
    final controller = EventCardController(
      eventId: event.id,
      preloadedEvent: event,
    );
    
    debugPrint('🔴 Controller criado, iniciando load()');
    // Iniciar carregamento dos dados adicionais em background
    controller.load();
    
    debugPrint('🔴 Abrindo showModalBottomSheet');
    // Abrir o card imediatamente (sem aguardar load)
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
            // Usar dados do evento pré-carregado
            final eventName = event.title;
            final emoji = event.emoji;
            
            // Criar User com dados do evento usando campos corretos do SessionManager
            final chatUser = User.fromDocument({
              'userId': 'event_${event.id}',
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
                  eventId: event.id,
                ),
              ),
            );
          }
        },
      ),
    ).whenComplete(() {
      // Garantir limpeza do controller ao fechar o modal
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Widget limpo - apenas UI
    // Toda lógica delegada ao ViewModel
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        // Mapa totalmente pronto: localização + eventos + markers carregados
        return AppleMap(
          // Callback de criação
          onMapCreated: _onMapCreated,

          // Posição inicial (São Paulo)
          initialCameraPosition: const CameraPosition(
            target: LatLng(-23.5505, -46.6333),
            zoom: 12.0,
          ),

          // Markers fornecidos pelo ViewModel
          annotations: widget.viewModel.eventMarkers,

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
    // Não fazemos dispose do ViewModel aqui pois ele vem de fora
    _mapController = null;
    super.dispose();
  }
}
