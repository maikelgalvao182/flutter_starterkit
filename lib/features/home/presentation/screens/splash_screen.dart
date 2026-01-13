import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/services/app_initializer_service.dart';
import 'package:partiu/core/services/auth_sync_service.dart';
import 'package:partiu/features/home/presentation/viewmodels/map_viewmodel.dart';
import 'package:partiu/features/home/presentation/viewmodels/people_ranking_viewmodel.dart';
import 'package:partiu/features/home/presentation/viewmodels/ranking_viewmodel.dart';
import 'package:partiu/features/conversations/state/conversations_viewmodel.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:provider/provider.dart';

/// Tela de Splash que roda apenas o bootstrap CRÍTICO antes de entrar no app.
///
/// IMPORTANTE:
/// - Esta tela executa apenas [AppInitializerService.initializeCritical] antes de navegar.
/// - Warmups pesados (mapa completo, conversas, rankings, etc.) rodam após o primeiro frame
///   na Home (background) ou on-demand ao abrir as telas.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitializing = false;
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImages();
      _initializeAndNavigate();
    });
  }

  void _precacheImages() {
    try {
      precacheImage(const AssetImage('assets/images/capa.jpg'), context);
      precacheImage(const AssetImage('assets/images/logo.png'), context);
    } catch (e) {
      AppLogger.warning('Erro no precache de imagens: $e', tag: 'SPLASH');
    }
  }
  
  /// Executa inicialização completa e navega para Home quando pronto
  Future<void> _initializeAndNavigate() async {
    if (_isInitializing) return;
    _isInitializing = true;

    AppLogger.info('Iniciando inicialização...', tag: 'SPLASH');

    try {
      // 1. Aguardar autenticação estar pronta
      final authSync = Provider.of<AuthSyncService>(context, listen: false);
      
      // Aguarda até que o AuthSyncService tenha inicializado
      int attempts = 0;
      while (!authSync.initialized && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      if (!authSync.initialized) {
        AppLogger.warning('Timeout aguardando AuthSyncService', tag: 'SPLASH');
      }
      
      // Se não está logado, ir direto para login
      if (!authSync.isLoggedIn) {
        AppLogger.info('Usuário não autenticado, indo para login', tag: 'SPLASH');
        _navigateToSignIn();
        return;
      }
      
      AppLogger.success('Usuário autenticado, iniciando AppInitializer...', tag: 'SPLASH');
      
      // 2. Obter ViewModels do Provider
      final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
      final peopleRankingViewModel = Provider.of<PeopleRankingViewModel>(context, listen: false);
      final locationsRankingViewModel = Provider.of<RankingViewModel>(context, listen: false);
      final conversationsViewModel = Provider.of<ConversationsViewModel>(context, listen: false);
      
      // Definir instância global (legado)
      PeopleRankingViewModel.instance = peopleRankingViewModel;
      
      // 3. Executar inicialização completa
      final initializer = AppInitializerService(
        mapViewModel,
        peopleRankingViewModel,
        locationsRankingViewModel,
        conversationsViewModel,
      );

      // 3. Executar apenas a parte CRÍTICA (sem travar com warmups pesados)
      await initializer.initializeCritical();

      AppLogger.success('Inicialização crítica concluída', tag: 'SPLASH');
      AppLogger.info('Eventos (até aqui): ${mapViewModel.events.length}', tag: 'SPLASH');
      AppLogger.info('Markers (até aqui): ${mapViewModel.googleMarkers.length}', tag: 'SPLASH');
      AppLogger.info('MapReady (até aqui): ${mapViewModel.mapReady}', tag: 'SPLASH');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro na inicialização do Splash (não bloqueia navegação)',
        tag: 'SPLASH',
        error: e,
        stackTrace: stackTrace,
      );
      // Não bloquear navegação - deixar app abrir mesmo com erro
    }
    
    // 4. Navegar para Home
    _navigateToHome();
  }
  
  void _navigateToSignIn() {
    if (!mounted) return;

    AppLogger.info('Navegando para SignIn...', tag: 'SPLASH');
    context.go('/sign-in');
  }
  
  void _navigateToHome() {
    if (!mounted) return;

    AppLogger.info('Navegando para Home...', tag: 'SPLASH');
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlimpseColors.primary,
      body: Center(
        child: Image.asset(
          'assets/images/logo_branca.png',
          width: 120,
          height: 120,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
