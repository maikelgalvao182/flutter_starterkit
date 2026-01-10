import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:partiu/features/web_dashboard/screens/dashboard_layout.dart';
import 'package:partiu/features/web_dashboard/screens/login_screen.dart';
import 'package:partiu/features/web_dashboard/services/web_auth_service.dart';
import 'package:partiu/firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:partiu/core/utils/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const WebDashboardApp());
}

class WebDashboardApp extends StatelessWidget {
  const WebDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) {
        final i18n = AppLocalizations.of(context);
        final title = i18n.translate('web_dashboard_title');
        return title.isNotEmpty ? title : i18n.translate('app_name');
      },
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      home: StreamBuilder<User?>(
        stream: WebAuthService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const DashboardLayout();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
