import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/app/services/localization_service.dart';
import 'package:partiu/shared/widgets/stable_avatar.dart';
import 'package:partiu/shared/widgets/skeletons/profile_header_skeleton.dart';
import 'package:partiu/shared/widgets/reactive/reactive_widgets.dart';
import 'package:partiu/shared/widgets/profile_completeness_ring.dart';
import 'package:partiu/features/profile/presentation/viewmodels/profile_tab_view_model.dart';
import 'package:partiu/features/profile/presentation/widgets/profile_info_chips.dart';
import 'package:partiu/features/profile/presentation/widgets/app_section_card.dart';
import 'package:partiu/features/profile/presentation/screens/profile_screen_router.dart';
import 'package:partiu/core/services/distance_unit_service.dart';

// ==================== PERFORMANCE OPTIMIZATIONS ====================
// Seguindo BOAS_PRATICAS2.MD:
// - Widgets const para evitar reconstruções
// - Cache de SVGs e TextStyles
// - Separação de responsabilidades para rebuild seletivo
//
// ==================== MVVM IMPROVEMENTS ====================
// Seguindo BOAS_PRATICAS.MD:
// - [OK] View não contém lógica de negócio
// - [OK] ViewModel não depende de BuildContext
// - [OK] Commands separam preparação de execução
// - [OK] Injeção de dependência explícita no ViewModel

/// ProfileTab - View pura seguindo padrão MVVM
/// 
/// Responsabilidades:
/// - Renderizar UI baseada no estado do ViewModel
/// - Delegar ações do usuário ao ViewModel (preparação)
/// - Executar navegação com BuildContext (após validação do ViewModel)
/// - Não conter lógica de negócio
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final ProfileTabViewModel _viewModel;
  
  // Cache de TextStyles para evitar recriação a cada build
  late TextStyle _nameTextStyle;

  @override
  void initState() {
    super.initState();
    // Inicializa o ViewModel apenas uma vez
    _viewModel = ProfileTabViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Cache de TextStyle - recriado apenas quando tema muda
    _nameTextStyle = GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
      color: Theme.of(context).textTheme.bodyLarge?.color,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
    
    // Inicializa ViewModel após primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _viewModel.shouldCheckCompleteness()) {
        _viewModel.executeCompletenessCheck(context);
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // ==================== EVENT HANDLERS ====================
  
  /// Handler: Navegar para visualização de perfil
  /// Usa Command pattern - ViewModel valida, View executa navegação
  Future<void> _handleViewProfileTap(BuildContext context) async {
    final command = _viewModel.prepareViewProfileNavigation();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (command == null) {
      // Usuário não autenticado - mostra feedback
      if (mounted) {
        _showErrorWithMessenger(scaffoldMessenger, 'Perfil do usuário não encontrado');
      }
      return;
    }
    
    try {
      await ProfileScreenRouter.navigateToProfile(
        context,
        user: command.user,
      );
    } catch (e) {
      if (mounted) {
        _showErrorWithMessenger(scaffoldMessenger, 'Erro ao carregar perfil do usuário');
      }
    }
  }
  
  /// Exibe toast de erro
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Exibe toast de erro usando ScaffoldMessenger já capturado
  void _showErrorWithMessenger(ScaffoldMessengerState scaffoldMessenger, String message) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Handler: Navegar para edição de perfil
  Future<void> _handleEditProfileTap(BuildContext context) async {
    final command = _viewModel.prepareEditProfileNavigation();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (command == null) {
      if (mounted) {
        _showErrorWithMessenger(scaffoldMessenger, 'Usuário não autenticado');
      }
      return;
    }
    
    try {
      await ProfileScreenRouter.navigateToEditProfile(context);
    } catch (e) {
      if (mounted) {
        _showErrorWithMessenger(scaffoldMessenger, 'Erro ao abrir edição de perfil');
      }
    }
  }
  
  /// Handler para atualizar foto de perfil
  Future<void> _handleUpdateProfilePhoto(BuildContext context) async {
    try {
      // TODO: Implementar seleção e upload de foto
      debugPrint('Selecionando nova foto de perfil');
    } catch (e) {
      if (mounted) {
        _showError(context, 'Erro no upload da foto');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return SingleChildScrollView(
              physics: GlimpseStyles.scrollPhysics,
              child: Column(
                children: [
                  // Header (título + botões de ação)
                  _ProfileHeader(
                    onViewProfile: () => _handleViewProfileTap(context),
                    onEditProfile: () => _handleEditProfileTap(context),
                  ),
                  const SizedBox(height: 8),
                  
                  // Profile header content
                  _ProfileHeaderContent(
                    viewModel: _viewModel,
                    nameTextStyle: _nameTextStyle,
                    onAvatarTap: () => _handleUpdateProfilePhoto(context),
                    onEditProfile: () => _handleEditProfileTap(context),
                  ),
                  const SizedBox(height: GlimpseStyles.mediumSpacing),

                  /// App Section Card
                  ChangeNotifierProvider(
                    create: (_) => DistanceUnitService(),
                    child: const AppSectionCard(),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==================== OPTIMIZED WIDGETS ====================

/// Widget otimizado para botão de ação com ícone SVG
class _IconButton extends StatelessWidget {
  
  const _IconButton({
    required this.assetPath,
    required this.tooltip,
    required this.onPressed,
  });
  final String assetPath;
  final String tooltip;
  final VoidCallback onPressed;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: SvgPicture.asset(
          assetPath,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            Theme.of(context).iconTheme.color!,
            BlendMode.srcIn,
          ),
        ),
        tooltip: tooltip,
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
      ),
    );
  }
}

/// Header da tab com título e botões de ação
class _ProfileHeader extends StatelessWidget {
  
  const _ProfileHeader({
    required this.onViewProfile,
    required this.onEditProfile,
  });
  final VoidCallback onViewProfile;
  final VoidCallback onEditProfile;
  
  @override
  Widget build(BuildContext context) {
    final i18n = LocalizationService.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              i18n.translate('profile') ?? 'Perfil',
              style: GlimpseStyles.messagesTitleStyle(
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Botões de ação
          _IconButton(
            assetPath: 'assets/svg/user-circle.svg',
            tooltip: i18n.translate('view_profile') ?? 'Ver Perfil',
            onPressed: onViewProfile,
          ),
          const SizedBox(width: 16),
          _IconButton(
            assetPath: 'assets/svg/edit-pen.svg',
            tooltip: i18n.translate('edit_profile') ?? 'Editar Perfil',
            onPressed: onEditProfile,
          ),
        ],
      ),
    );
  }
}

/// Conteúdo do header do perfil (avatar, nome, chips)
class _ProfileHeaderContent extends StatelessWidget {
  
  const _ProfileHeaderContent({
    required this.viewModel,
    required this.nameTextStyle,
    required this.onAvatarTap,
    required this.onEditProfile,
  });
  final ProfileTabViewModel viewModel;
  final TextStyle nameTextStyle;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final user = viewModel.currentUser;
    
    // Show skeleton if user data is not loaded yet
    if (!viewModel.isUserDataLoaded || user == null) {
      return const ProfileHeaderSkeleton();
    }
    
    // Show actual profile data
    return Column(
      children: [
        // Avatar com Progress Ring REATIVO
        Center(
          child: ValueListenableBuilder<User?>(
            valueListenable: AppState.currentUser,
            builder: (context, currentUser, _) {
              if (currentUser == null) {
                return const SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(),
                );
              }
              
              // Calcula porcentagem de completude
              final percentage = viewModel.calculateCompletenessPercentage();
              
              return ProfileCompletenessRing(
                size: 100,
                strokeWidth: 3,
                percentage: percentage,
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: StableAvatar(
                    userId: currentUser.userId,
                    size: 88,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        
        // Nome completo
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ReactiveUserNameWithBadge(
              userId: user.userId,
              style: nameTextStyle,
              iconSize: 14,
              spacing: 6,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Localização + Visits
        const ProfileInfoChips(),
      ],
    );
  }
}
