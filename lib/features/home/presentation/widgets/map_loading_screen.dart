import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Tela de loading para inicialização do mapa
/// 
/// Exibida apenas na primeira carga, enquanto:
/// - Localização é obtida
/// - Eventos são carregados
/// - Eventos são enriquecidos
/// - Markers são gerados
class MapLoadingScreen extends StatelessWidget {
  const MapLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CupertinoActivityIndicator(
          radius: 14,
          color: GlimpseColors.textSubTitle,
        ),
      ),
    );
  }
}
