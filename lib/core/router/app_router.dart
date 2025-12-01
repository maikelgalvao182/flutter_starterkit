import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:partiu/features/auth/presentation/screens/sign_in_screen_refactored.dart';
import 'package:partiu/features/auth/presentation/screens/signup_wizard_screen.dart';
import 'package:partiu/features/auth/presentation/screens/email_auth_screen.dart';
import 'package:partiu/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:partiu/features/auth/presentation/screens/blocked_account_screen_router.dart';
import 'package:partiu/features/location/presentation/screens/update_location_screen_router.dart';
import 'package:partiu/features/home/presentation/screens/home_screen_refactored.dart';
import 'package:partiu/features/profile/presentation/screens/profile_screen.dart';
import 'package:partiu/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:partiu/shared/widgets/glimpse_button.dart';
import 'package:partiu/features/auth/presentation/widgets/signup_widgets.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/core/models/user.dart';

/// Rotas da aplicação
class AppRoutes {
  static const String signIn = '/sign-in';
  static const String emailAuth = '/email-auth';
  static const String forgotPassword = '/forgot-password';
  static const String signupWizard = '/signup-wizard';
  static const String signupSuccess = '/signup-success';
  static const String updateLocation = '/update-location';
  static const String home = '/home';
  static const String blocked = '/blocked';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
}

/// Configuração do GoRouter
final goRouter = GoRouter(
  initialLocation: AppRoutes.signIn,
  debugLogDiagnostics: true,
  routes: [
    // Tela de Login
    GoRoute(
      path: AppRoutes.signIn,
      name: 'signIn',
      builder: (context, state) => const SignInScreenRefactored(),
    ),
    
    // Tela de Email/Senha Auth
    GoRoute(
      path: AppRoutes.emailAuth,
      name: 'emailAuth',
      builder: (context, state) => const EmailAuthScreen(),
    ),
    
    // Tela de Recuperação de Senha
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    
    // Wizard de Cadastro
    GoRoute(
      path: AppRoutes.signupWizard,
      name: 'signupWizard',
      builder: (context, state) => const SignupWizardScreen(),
    ),
    
    // Tela de Sucesso após Cadastro
    GoRoute(
      path: AppRoutes.signupSuccess,
      name: 'signupSuccess',
      builder: (context, state) => const SignupSuccessScreen(),
    ),
    
    // Atualização de Localização
    GoRoute(
      path: AppRoutes.updateLocation,
      name: 'updateLocation',
      builder: (context, state) => const UpdateLocationScreenRouter(),
    ),
    
    // Home
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreenRefactored(),
    ),
    
    // Blocked Account
    GoRoute(
      path: AppRoutes.blocked,
      name: 'blocked',
      builder: (context, state) => const BlockedAccountScreenRouter(),
    ),
    
    // Profile
    GoRoute(
      path: AppRoutes.profile,
      name: 'profile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(
            body: Center(
              child: Text('Dados do perfil não encontrados'),
            ),
          );
        }
        
        final user = extra['user'] as User;
        final currentUserId = extra['currentUserId'] as String;
        
        return ProfileScreen(
          user: user,
          currentUserId: currentUserId,
        );
      },
    ),
    
    // Edit Profile
    GoRoute(
      path: AppRoutes.editProfile,
      name: 'editProfile',
      builder: (context, state) => const EditProfileScreen(),
    ),
  ],
  
  // Tratamento de erro
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Erro: ${state.error}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.signIn),
            child: const Text('Voltar ao Login'),
          ),
        ],
      ),
    ),
  ),
);

/// Tela de sucesso após cadastro
class SignupSuccessScreen extends StatelessWidget {
  const SignupSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlimpseColors.bgColorLight,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Expanded(child: SignupSuccessWidget()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: GlimpseButton(
                text: AppLocalizations.of(context).translate('continue'),
                onTap: () {
                  // Navega para atualização de localização e remove histórico
                  context.go(AppRoutes.updateLocation);
                },
                backgroundColor: GlimpseColors.primaryColorLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
