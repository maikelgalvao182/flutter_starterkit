import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:partiu/core/services/app_initializer_service.dart';
import 'package:partiu/features/home/presentation/screens/home_screen_refactored.dart';
import 'package:partiu/features/home/presentation/viewmodels/map_viewmodel.dart';
import 'package:partiu/features/home/presentation/viewmodels/people_ranking_viewmodel.dart';
import 'package:partiu/features/home/presentation/screens/find_people/find_people_controller.dart';
import 'package:provider/provider.dart';

/// Tela de Splash que carrega todos os dados do mapa antes de entrar no app
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ViewModels instanciados aqui e passados para frente
  final MapViewModel mapViewModel = MapViewModel();
  final PeopleRankingViewModel peopleRankingViewModel = PeopleRankingViewModel();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Serviço de inicialização
    final initializer = AppInitializerService(
      mapViewModel,
      peopleRankingViewModel,
    );
    
    // Definir instância global para acesso compartilhado
    PeopleRankingViewModel.instance = peopleRankingViewModel;

    // Aguarda tudo ficar pronto (localização, eventos, markers, rankings)
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
        peopleRankingViewModel: peopleRankingViewModel,
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
