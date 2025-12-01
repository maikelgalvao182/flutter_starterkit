import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_country_selector/flutter_country_selector.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:partiu/firebase_options.dart';
import 'package:partiu/core/config/dependency_provider.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/core/managers/session_manager.dart';
import 'package:partiu/core/services/cache/cache_manager.dart';
import 'package:partiu/core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar SessionManager
  await SessionManager.instance.initialize();

  // Inicializar CacheManager
  CacheManager.instance.initialize();

  // Inicializar Service Locator
  final serviceLocator = ServiceLocator();
  await serviceLocator.init();

  runApp(MyApp(serviceLocator: serviceLocator));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.serviceLocator});

  final ServiceLocator serviceLocator;

  @override
  Widget build(BuildContext context) {
    return DependencyProvider(
      serviceLocator: serviceLocator,
      child: MaterialApp.router(
        title: 'Partiu',
        debugShowCheckedModeBanner: false,
        
        // Configuração de rotas com go_router
        routerConfig: goRouter,
        
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
      ),
    );
  }
}
