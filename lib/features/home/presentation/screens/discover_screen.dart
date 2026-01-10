import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:partiu/features/home/presentation/widgets/google_map_view.dart';
import 'package:partiu/features/home/presentation/viewmodels/map_viewmodel.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

/// Tela de descoberta de atividades com mapa interativo
/// 
/// Esta tela exibe um mapa Google Maps com a localização do usuário.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key, 
    this.onCenterUserRequested,
    required this.mapViewModel,
  });

  final VoidCallback? onCenterUserRequested;
  final MapViewModel mapViewModel;

  @override
  State<DiscoverScreen> createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> {
  final GlobalKey<GoogleMapViewState> _mapKey = GlobalKey<GoogleMapViewState>();
  bool _platformMapCreated = false;

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
    return Stack(
      children: [
        ColoredBox(
          color: Colors.white,
          child: GoogleMapView(
            key: _mapKey,
            viewModel: widget.mapViewModel,
            onPlatformMapCreated: () {
              if (!mounted || _platformMapCreated) return;
              setState(() {
                _platformMapCreated = true;
              });
            },
          ),
        ),

        if (!_platformMapCreated)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white,
              child: Center(
                child: CupertinoActivityIndicator(
                  color: GlimpseColors.textSubTitle,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Centraliza o mapa na localização do usuário
  void centerOnUser() {
    _mapKey.currentState?.centerOnUser();
  }
}
