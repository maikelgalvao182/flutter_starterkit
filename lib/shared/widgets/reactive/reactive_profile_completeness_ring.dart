import 'package:flutter/material.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/features/profile/presentation/viewmodels/profile_tab_view_model.dart';
import 'package:partiu/shared/widgets/profile_completeness_ring.dart';

/// 🎯 Anel de completude de perfil reativo
/// Reconstrói APENAS quando o usuário logado muda no AppState
/// 
/// Calcula automaticamente a porcentagem via ProfileTabViewModel
/// e exibe o anel de progresso ao redor do avatar.
/// 
/// Usage:
/// ```dart
/// ReactiveProfileCompletenessRing(
///   size: 100,
///   child: StableAvatar(...),
/// )
/// 
/// // Com customização
/// ReactiveProfileCompletenessRing(
///   size: 120,
///   strokeWidth: 4,
///   child: StableAvatar(...),
/// )
/// ```
class ReactiveProfileCompletenessRing extends StatefulWidget {
  const ReactiveProfileCompletenessRing({
    required this.size,
    required this.child,
    this.strokeWidth = 4.0,
    super.key,
  });

  final double size;
  final Widget child;
  final double strokeWidth;

  @override
  State<ReactiveProfileCompletenessRing> createState() =>
      _ReactiveProfileCompletenessRingState();
}

class _ReactiveProfileCompletenessRingState
    extends State<ReactiveProfileCompletenessRing> {
  late final ProfileTabViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileTabViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppState.currentUser,
      builder: (context, user, _) {
        // Calcula percentual via ViewModel (separação de responsabilidades)
        final percentage = user != null
            ? _viewModel.calculateCompletenessPercentage()
            : 0;

        return ProfileCompletenessRing(
          size: widget.size,
          strokeWidth: widget.strokeWidth,
          percentage: percentage,
          child: widget.child,
        );
      },
    );
  }
}
