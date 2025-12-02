import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:partiu/features/profile/data/repositories/profile_repository.dart';
import 'package:partiu/features/profile/domain/repositories/profile_repository_interface.dart';
import 'package:partiu/features/profile/presentation/viewmodels/edit_profile_view_model.dart';

/// Provider de dependências para o módulo de Profile
/// Centraliza a configuração de injeção de dependências
class ProfileDependencyProvider extends StatelessWidget {
  final Widget child;
  
  const ProfileDependencyProvider({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repository
        Provider<IProfileRepository>(
          create: (_) => ProfileRepository(),
        ),
        
        // ViewModel
        ChangeNotifierProvider<EditProfileViewModel>(
          create: (context) => EditProfileViewModel(
            profileRepository: context.read<IProfileRepository>(),
          ),
        ),
      ],
      child: child,
    );
  }
}
