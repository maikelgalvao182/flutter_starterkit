import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:partiu/core/services/app_initializer_service.dart';
import 'package:partiu/features/home/presentation/screens/home_screen_refactored.dart';
import 'package:partiu/features/home/presentation/viewmodels/map_viewmodel.dart';

/// Tela de Splash que carrega todos os dados do mapa antes de entrar no app
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ViewModel instanciado aqui e passado para frente
  final MapViewModel mapViewModel = MapViewModel();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Serviço de inicialização
    final initializer = AppInitializerService(mapViewModel);

    // Aguarda tudo ficar pronto (localização, eventos, markers)
    await initializer.initialize();

    if (!mounted) return;

    // Marca como pronto para exibir a Home
    setState(() {
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Se já estiver pronto, exibe a Home diretamente
    if (_isReady) {
      return HomeScreenRefactored(
        mapViewModel: mapViewModel,
      );
    }

    // Caso contrário, exibe loading
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CupertinoActivityIndicator(
          radius: 16,
          color: CupertinoColors.activeBlue,
        ),
      ),
    );
  }
}
