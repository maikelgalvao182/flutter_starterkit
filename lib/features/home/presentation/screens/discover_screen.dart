import 'package:flutter/material.dart';
import 'package:partiu/features/home/presentation/widgets/apple_map_view.dart';

/// Tela de descoberta de atividades com mapa interativo
/// 
/// Esta tela exibe um mapa Apple Maps com a localização do usuário.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.onCenterUserRequested});

  final VoidCallback? onCenterUserRequested;

  @override
  State<DiscoverScreen> createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> {
  final GlobalKey<AppleMapViewState> _mapKey = GlobalKey<AppleMapViewState>();

  @override
  void initState() {
    super.initState();
    // Notifica o callback quando o widget é criado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCenterUserRequested?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: AppleMapView(key: _mapKey),
    );
  }

  /// Centraliza o mapa na localização do usuário
  void centerOnUser() {
    _mapKey.currentState?.centerOnUser();
  }
}
