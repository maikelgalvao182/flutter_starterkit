import 'dart:async';

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
    this.onFirstMapScroll,
    required this.mapViewModel,
  });

  final VoidCallback? onCenterUserRequested;
  /// Callback chamado quando o primeiro scroll do mapa ocorre (para onboarding)
  final VoidCallback? onFirstMapScroll;
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

      // 🚀 Lazy init do mapa: não travar Splash/Home.
      // Só inicializa se ainda não houver dados (idempotência via estado do VM).
      final vm = widget.mapViewModel;
      final hasData = vm.mapReady || vm.events.isNotEmpty || vm.googleMarkers.isNotEmpty;
      if (!hasData) {
        unawaited(() async {
          try {
            await vm.initialize();
          } catch (_) {
            // Inicialização do mapa não é crítica para navegação.
          }
        }());
      }
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
            onFirstMapScroll: widget.onFirstMapScroll,
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
