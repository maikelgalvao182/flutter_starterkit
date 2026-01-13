import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:partiu/features/home/presentation/services/onboarding_service.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Widget de onboarding com liquid swipe para novos usuários.
/// 
/// Exibe 5 telas explicativas sobre o app:
/// 1. Posicionamento - "O Boora não é um app de namoro"
/// 2. Verificação - "Prefira perfis verificados"
/// 3. Reputação - "A reputação importa"
/// 4. Segurança - "Sua segurança vem primeiro"
/// 5. Denúncia - "Denúncia"
class LiquidSwipeOnboarding extends StatefulWidget {
  const LiquidSwipeOnboarding({
    super.key,
    required this.onComplete,
  });

  /// Callback chamado quando o onboarding é completado
  final VoidCallback onComplete;

  @override
  State<LiquidSwipeOnboarding> createState() => _LiquidSwipeOnboardingState();
}

class _LiquidSwipeOnboardingState extends State<LiquidSwipeOnboarding> {
  final LiquidController _liquidController = LiquidController();
  int _currentPage = 0;
  bool _isCompleting = false;

  // Cores vibrantes para cada tela
  static const Color _screenColor1 = Color(0xFF5BAD46); // Primary verde
  static const Color _screenColor2 = Color(0xFF2196F3); // Azul vibrante
  static const Color _screenColor3 = Color(0xFFFF9800); // Laranja vibrante
  static const Color _screenColor4 = Color(0xFF9C27B0); // Roxo vibrante
  static const Color _screenColor5 = Color(0xFFE53935); // Vermelho (denúncia)

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 [LiquidSwipeOnboarding] initState chamado');
  }

  @override
  void dispose() {
    debugPrint('🗑️ [LiquidSwipeOnboarding] dispose chamado');
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    debugPrint('✅ [LiquidSwipeOnboarding] _completeOnboarding chamado');
    
    if (_isCompleting) {
      debugPrint('   ⏭️ Já está completando, ignorando');
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    try {
      debugPrint('   💾 Marcando onboarding como completado...');
      await OnboardingService.instance.markOnboardingCompleted();
      
      debugPrint('   mounted: $mounted');
      if (!mounted) {
        debugPrint('   ⚠️ Widget não está montado, abortando callback');
        return;
      }
      
      debugPrint('   🎯 Chamando widget.onComplete()');
      widget.onComplete();
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [LiquidSwipeOnboarding] build chamado');
    debugPrint('   _currentPage: $_currentPage');
    debugPrint('   _isCompleting: $_isCompleting');
    
    final pages = _buildPages(context);
    debugPrint('   📄 Páginas construídas: ${pages.length}');
    
    final isLastPage = _currentPage == pages.length - 1;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    
    debugPrint('   isLastPage: $isLastPage');
    debugPrint('   bottomInset: $bottomInset');

    return PopScope(
      canPop: false, // usuário não pode sair até concluir onboarding
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentPage > 0) {
          _liquidController.animateToPage(page: _currentPage - 1);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Fundo fullscreen (cobrindo safe areas)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: (!_isCompleting && isLastPage) ? _completeOnboarding : null,
                child: LiquidSwipe(
                  pages: pages,
                  liquidController: _liquidController,
                  onPageChangeCallback: _onPageChanged,
                  waveType: WaveType.liquidReveal,
                  slideIconWidget: isLastPage
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white70,
                          size: 20,
                        ),
                  positionSlideIcon: 0.54,
                  enableSideReveal: true,
                  enableLoop: false,
                  ignoreUserGestureWhileAnimating: true,
                ),
              ),
            ),

            // Overlays respeitando safe area (sem “cortar” em notch/home indicator)
            SafeArea(
              child: Stack(
                children: [
                  // Indicadores de página
                  if (!isLastPage)
                    Positioned(
                      bottom: 60 + bottomInset,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (index) => _buildPageIndicator(index),
                        ),
                      ),
                    ),

                  if (isLastPage)
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 16 + bottomInset,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isCompleting ? null : _completeOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isCompleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black87,
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context).translate('finish'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),

                  // Botões de navegação
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  List<Widget> _buildPages(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return [
      _OnboardingPage(
        backgroundColor: _screenColor1,
        imageAssetPath: 'assets/images/onboarding/on1.png',
        title: i18n.translate('onboarding_positioning_title'),
        subtitle: '',
        subtitleSpans: [
          TextSpan(text: i18n.translate('onboarding_intro_line1')),
          TextSpan(text: i18n.translate('onboarding_intro_prefix')),
          TextSpan(
            text: i18n.translate('onboarding_intro_bold'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: i18n.translate('onboarding_intro_suffix')),
        ],
      ),
      _OnboardingPage(
        backgroundColor: _screenColor2,
        imageAssetPath: 'assets/images/onboarding/on2.png',
        title: i18n.translate('onboarding_verified_title'),
        subtitle: i18n.translate('onboarding_verified_text'),
      ),
      _OnboardingPage(
        backgroundColor: _screenColor3,
        imageAssetPath: 'assets/images/onboarding/on3.png',
        title: i18n.translate('onboarding_reputation_title'),
        subtitle: i18n.translate('onboarding_reputation_text'),
      ),
      _OnboardingPage(
        backgroundColor: _screenColor4,
        imageAssetPath: 'assets/images/onboarding/on4.png',
        title: i18n.translate('onboarding_safety_title'),
        subtitle: i18n.translate('onboarding_safety_text'),
      ),
      _OnboardingPage(
        backgroundColor: _screenColor5,
        imageAssetPath: 'assets/images/onboarding/on5.png',
        title: i18n.translate('onboarding_report_title'),
        subtitle: i18n.translate('onboarding_report_text'),
      ),
    ];
  }
}

/// Página individual do onboarding
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.backgroundColor,
    this.icon,
    this.imageAssetPath,
    this.subtitleSpans,
    required this.title,
    required this.subtitle,
  }) : assert(
          icon != null || imageAssetPath != null,
          'Informe icon ou imageAssetPath',
        );

  final Color backgroundColor;
  final IconData? icon;
  final String? imageAssetPath;
  final String title;
  final String subtitle;
  final List<InlineSpan>? subtitleSpans;

  @override
  Widget build(BuildContext context) {
    const double imageSize = 168;
    const double imageContainerPadding = 36;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 344),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone grande
                Container(
                  padding: const EdgeInsets.all(imageContainerPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: imageAssetPath != null
                      ? Image.asset(
                          imageAssetPath!,
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.contain,
                          opacity: const AlwaysStoppedAnimation(0.92),
                          semanticLabel: title,
                        )
                      : Icon(
                          icon,
                          size: 80,
                          color: Colors.white,
                        ),
                ),

                const SizedBox(height: 48),

                // Título
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 20),

                // Subtítulo
                (subtitleSpans != null)
                    ? RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.5,
                          ),
                          children: subtitleSpans,
                        ),
                      )
                    : Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),

                // Espaço final leve (safe area/indicadores)
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
