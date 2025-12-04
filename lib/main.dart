import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_country_selector/flutter_country_selector.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:partiu/firebase_options.dart';
import 'package:partiu/core/config/dependency_provider.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/core/managers/session_manager.dart';
import 'package:partiu/core/services/cache/cache_manager.dart';
import 'package:partiu/core/services/google_maps_initializer.dart';
import 'package:partiu/core/router/app_router.dart';
import 'package:partiu/core/services/auth_sync_service.dart';
import 'package:partiu/core/services/location_service.dart';
import 'package:partiu/core/services/location_background_updater.dart'; // LocationSyncScheduler
import 'package:partiu/features/conversations/state/conversations_viewmodel.dart';
import 'package:partiu/features/subscription/providers/simple_subscription_provider.dart';
import 'package:brazilian_locations/brazilian_locations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar BrazilianLocations
  await BrazilianLocations.initialize();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Google Maps
  await GoogleMapsInitializer.initialize();

  // Inicializar SessionManager
  await SessionManager.instance.initialize();

  // Inicializar CacheManager
  CacheManager.instance.initialize();

  // Inicializar Service Locator
  final serviceLocator = ServiceLocator();
  await serviceLocator.init();

  // Inicializar LocationSyncScheduler para atualização automática de localização
  // Isso mantém o Firestore atualizado a cada 10 minutos automaticamente
  final locationService = serviceLocator.get<LocationService>();
  LocationSyncScheduler.start(
    locationService,
    config: LocationConfig.standard, // Usar configuração padrão (Uber/Tinder)
  );
  debugPrint('✅ LocationSyncScheduler iniciado');

  runApp(
    MultiProvider(
      providers: [
        // AuthSyncService como singleton - ÚNICA fonte de verdade para auth
        ChangeNotifierProvider(
          create: (_) => AuthSyncService(),
        ),
        // ConversationsViewModel - gerencia estado das conversas
        ChangeNotifierProvider(
          create: (_) => ConversationsViewModel(),
        ),
        // SimpleSubscriptionProvider - gerencia estado de assinaturas VIP
        ChangeNotifierProvider(
          create: (_) => SimpleSubscriptionProvider(),
        ),
        // DependencyProvider via Provider para compatibility
        Provider<ServiceLocator>.value(
          value: serviceLocator,
        ),
      ],
      child: DependencyProvider(
        serviceLocator: serviceLocator,
        child: const AuthInitializationGate(),
      ),
    ),
  );
}

/// Widget que aguarda o AuthSyncService ser inicializado antes de mostrar a UI principal.
/// Isso evita mostrar telas incorretas durante o boot do app.
class AuthInitializationGate extends StatelessWidget {
  const AuthInitializationGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthSyncService>(
      builder: (context, authSync, child) {
        // Aguarda inicialização do AuthSyncService
        if (!authSync.initialized) {
          return const MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Verificando autenticação...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // AuthSyncService inicializado - pode mostrar app principal
        return const MyApp();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cria goRouter com acesso ao AuthSyncService via context
    final router = createAppRouter(context);
    
    return MaterialApp.router(
      title: 'Partiu',
      debugShowCheckedModeBanner: false,
      
      // Configuração de rotas com go_router protegido por AuthSyncService
      routerConfig: router,
        
      // Configuração de localização
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        CountrySelectorLocalization.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Português
        Locale('en', 'US'), // Inglês
        Locale('es', 'ES'), // Espanhol
      ],
      locale: const Locale('pt', 'BR'), // Idioma padrão
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
