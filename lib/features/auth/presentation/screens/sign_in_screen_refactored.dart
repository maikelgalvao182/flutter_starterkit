import 'dart:io';

import 'package:partiu/core/constants/text_styles.dart';
import 'package:partiu/core/constants/toast_messages.dart';
import 'package:partiu/core/config/dependency_provider.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/models/user_model.dart';
import 'package:partiu/features/auth/presentation/controllers/sign_in_view_model.dart';
import 'package:partiu/core/router/app_router.dart';
import 'package:partiu/shared/widgets/cached_svg_icon.dart';
import 'package:partiu/core/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SignInScreenRefactored extends StatefulWidget {
  const SignInScreenRefactored({super.key});

  @override
  SignInScreenRefactoredState createState() => SignInScreenRefactoredState();
}

class SignInScreenRefactoredState extends State<SignInScreenRefactored> {
  // Variables
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AppLocalizations _i18n;
  late SignInViewModel _viewModel;
  
  // Flags para prevenir cliques duplicados
  bool _isAppleSignInProcessing = false;
  bool _isGoogleSignInProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtém o ViewModel através do ServiceLocator
    _viewModel = DependencyProvider.of(context).serviceLocator.get<SignInViewModel>();
  }

  // Handle User Auth
  void _checkUserAccount() {
    /// Auth user account usando o ViewModel
    _viewModel.authUserAccount(
      updateLocationScreen: () {
        // Navega para atualização de localização
        context.go(AppRoutes.updateLocation);
      },
      signUpScreen: () {
        // Navega para wizard de cadastro
        context.go(AppRoutes.signupWizard);
      },
      homeScreen: () {
        // Navega para home após login bem-sucedido
        context.go(AppRoutes.home);
      },
      blockedScreen: () {
        // Navega para tela de conta bloqueada
        context.go(AppRoutes.blocked);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

    const systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android white icons
      statusBarBrightness: Brightness.dark, // iOS white icons
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Image(
              image: AssetImage('assets/images/background_image.jpg'),
              fit: BoxFit.cover,
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  /// Close button (top-right) for guest mode navigation with background
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 16),
                      child: GestureDetector(
                        onTap: () {
                          // Navega para Home usando go_router
                          context.go(AppRoutes.home);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  /// Top section with logo and texts
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// App logo white version above main logo (46px)
                        const SizedBox(
                          width: 46,
                          height: 46,
                          child: CachedSvgIcon(
                            'assets/svg/app_logo_branca.svg',
                          ),
                        ),
                        const SizedBox(height: 0),
                        /// App logo (constrained to ~50% of screen width)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxW = constraints.maxWidth.isFinite
                                ? constraints.maxWidth
                                : MediaQuery.of(context).size.width;
                            final logoW = maxW * 0.5; // 50% of available width
                            return Transform.translate(
                              offset: const Offset(0, -16), // reduce vertical gap between logos
                              child: SizedBox(
                                width: logoW,
                                child: const CachedSvgIcon(
                                  'assets/svg/logo_branca.svg',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 0),
                        // Texts moved to bottom section to match Glimpse position/style
                        const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  /// Bottom section with buttons and terms
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Glimpse-like title and subtitle above the buttons
                          Padding(
                            padding: const EdgeInsets.only(left: 25, right: 25, bottom: 5),
                            child: Text(
                              _i18n.translate('auth_title').isNotEmpty 
                                ? _i18n.translate('auth_title')
                                : 'Where Wedding Dreams\nMeet Reality',
                              style: TextStyles.authTitle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                          child: Text(
                            _i18n.translate('auth_subtitle').isNotEmpty
                              ? _i18n.translate('auth_subtitle')
                              : 'We connect brides and grooms with nearby vendors through transparent, budget-conscious matchmaking.',
                            style: TextStyles.authSubtitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 18),
                        /// Sign in with Apple (iOS only)
                        if (Platform.isIOS) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                            child: GestureDetector(
                              onTap: () async {
                                // Prevenir cliques duplicados
                                if (_isAppleSignInProcessing || _viewModel.isLoading) {
                                  return;
                                }
                                
                                setState(() {
                                  _isAppleSignInProcessing = true;
                                });
                                
                                try {
                                  // Login with Apple usando o ViewModel
                                  await _viewModel.signInWithApple(
                                  checkUserAccount: _checkUserAccount,
                                  onNameReceived: (name) async {
                                    await UserModel(userId: "temp").setOAuthDisplayName(name);
                                  },
                                  onNotAvailable: () {
                                    // Show user-friendly message for Apple Sign-In not available
                                    ToastService.showError(
                                      message: ToastMessages.appleSignInNotAvailable,
                                    );
                                  },
                                  onError: (error) {
                                    // Handle specific Apple Sign-In errors
                                    if (error.message?.contains('canceled') == true || 
                                        error.message?.contains('cancelled') == true ||
                                        error.code == 'sign_in_canceled') {
                                      // User canceled sign-in
                                      ToastService.showError(
                                        message: ToastMessages.signInCanceledMessage,
                                      );
                                    } else {
                                      // Other Apple Sign-In errors
                                      ToastService.showError(
                                        message: (error.message as String?) ?? ToastMessages.anErrorOccurred,
                                      );
                                    }
                                    // Debug
                                  },
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isAppleSignInProcessing = false;
                                    });
                                  }
                                }
                              },
                              child: Container(
                                width: double.maxFinite,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: (_isAppleSignInProcessing || _viewModel.isLoading)
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CachedSvgIcon(
                                        'assets/icons/apple_icon.svg',
                                        width: 22,
                                        height: 22,
                                        color: (_isAppleSignInProcessing || _viewModel.isLoading)
                                            ? Colors.black.withValues(alpha: 0.5)
                                            : Colors.black,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _i18n.translate('sign_in_with_apple').isNotEmpty
                                            ? _i18n.translate('sign_in_with_apple')
                                            : 'Continue with Apple',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: (_isAppleSignInProcessing || _viewModel.isLoading)
                                              ? Colors.black.withValues(alpha: 0.5)
                                              : Colors.black,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        /// Sign in with Facebook (hidden)
                        const SizedBox.shrink(),
                        const SizedBox(height: 10),
                        /// Sign in with Google
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                          child: GestureDetector(
                            onTap: () async {
                              // Prevenir cliques duplicados
                              if (_isGoogleSignInProcessing || _viewModel.isLoading) {
                                return;
                              }
                              
                              setState(() {
                                _isGoogleSignInProcessing = true;
                              });
                              
                              try {
                                // Login with Google usando o ViewModel
                                await _viewModel.signInWithGoogle(
                                checkUserAccount: _checkUserAccount,
                                onNameReceived: (name) async {
                                  await UserModel(userId: "temp").setOAuthDisplayName(name);
                                },
                                onError: (error) {
                                  // Handle specific Google Sign-In errors
                                  if (error.message?.contains('canceled') == true || 
                                      error.message?.contains('cancelled') == true ||
                                      error.code == 'sign_in_canceled' ||
                                      error.code == 'network_error') {
                                    // User canceled sign-in or network issues
                                    ToastService.showError(
                                      message: ToastMessages.signInCanceledMessage,
                                    );
                                  } else {
                                    // Other Google Sign-In errors
                                    ToastService.showError(
                                      message: (error.message as String?) ?? ToastMessages.anErrorOccurred,
                                    );
                                  }
                                },
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isGoogleSignInProcessing = false;
                                  });
                                }
                              }
                            },
                            child: Container(
                              width: double.maxFinite,
                              height: 55,
                              decoration: BoxDecoration(
                                color: (_isGoogleSignInProcessing || _viewModel.isLoading)
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CachedSvgIcon(
                                      'assets/icons/google_icon.svg',
                                      width: 22,
                                      height: 22,
                                      color: (_isGoogleSignInProcessing || _viewModel.isLoading)
                                          ? Colors.black.withValues(alpha: 0.5)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _i18n.translate('sign_in_with_google').isNotEmpty
                                          ? _i18n.translate('sign_in_with_google')
                                          : 'Continue with Google',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: (_isGoogleSignInProcessing || _viewModel.isLoading)
                                            ? Colors.black.withValues(alpha: 0.5)
                                            : Colors.black,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        /// Sign in with Email
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                          child: SizedBox(
                            height: 55,
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  // Navegar para tela de email/senha usando go_router
                                  context.push(AppRoutes.emailAuth);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.email_outlined,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _i18n.translate('sign_in_with_email').isNotEmpty
                                            ? _i18n.translate('sign_in_with_email')
                                            : 'Continue with Email',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        /// Sign in with Phone Number (disabled / hidden)
                        const SizedBox.shrink(),
                        const SizedBox(height: 16),
                        /// Terms of Service section (hidden)
                        const SizedBox.shrink(),
                      ],
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
