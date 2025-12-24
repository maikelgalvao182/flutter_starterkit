import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:partiu/core/services/app_initializer_service.dart';
import 'package:partiu/core/services/auth_sync_service.dart';
import 'package:partiu/features/home/presentation/viewmodels/map_viewmodel.dart';
import 'package:partiu/features/home/presentation/viewmodels/people_ranking_viewmodel.dart';
import 'package:partiu/features/home/presentation/viewmodels/ranking_viewmodel.dart';
import 'package:partiu/features/conversations/state/conversations_viewmodel.dart';
import 'package:provider/provider.dart';

/// Tela de Splash que carrega todos os dados do mapa antes de entrar no app
/// 
/// IMPORTANTE: Esta tela executa o AppInitializerService ANTES de navegar para o Home.
/// Isso garante que:
/// - Todos os dados do mapa estejam pré-carregados
/// - Bitmaps dos markers estejam em cache
/// - Rankings, conversas e outros dados estejam prontos
/// - Usuário não veja tela vazia após o splash
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
      debugPrint('Erro no precache: $e');
    }
  }
  
  /// Executa inicialização completa e navega para Home quando pronto
  Future<void> _initializeAndNavigate() async {
    if (_isInitializing) return;
    _isInitializing = true;
    
    debugPrint('🚀 [SplashScreen] Iniciando inicialização...');
    
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
        debugPrint('⚠️ [SplashScreen] Timeout aguardando AuthSyncService');
      }
      
      // Se não está logado, ir direto para login
      if (!authSync.isLoggedIn) {
        debugPrint('ℹ️ [SplashScreen] Usuário não autenticado, indo para login');
        _navigateToSignIn();
        return;
      }
      
      debugPrint('✅ [SplashScreen] Usuário autenticado, iniciando AppInitializer...');
      
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
      
      await initializer.initialize();
      
      debugPrint('✅ [SplashScreen] Inicialização completa!');
      debugPrint('   - Eventos: ${mapViewModel.events.length}');
      debugPrint('   - Markers: ${mapViewModel.googleMarkers.length}');
      debugPrint('   - Mapa pronto: ${mapViewModel.mapReady}');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [SplashScreen] Erro na inicialização: $e');
      debugPrint('Stack: $stackTrace');
      // Não bloquear navegação - deixar app abrir mesmo com erro
    }
    
    // 4. Navegar para Home
    _navigateToHome();
  }
  
  void _navigateToSignIn() {
    if (!mounted) return;
    
    debugPrint('🔐 [SplashScreen] Navegando para SignIn...');
    context.go('/sign-in');
  }
  
  void _navigateToHome() {
    if (!mounted) return;
    
    debugPrint('🏠 [SplashScreen] Navegando para Home...');
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 120,
          height: 120,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
