import 'package:flutter/material.dart';
import 'package:partiu/core/models/user.dart';

/// Serviço para gerenciar prompts de completude do perfil
class ProfileCompletenessPromptService {
  ProfileCompletenessPromptService._();
  
  static final ProfileCompletenessPromptService _instance = ProfileCompletenessPromptService._();
  static ProfileCompletenessPromptService get instance => _instance;

  /// Calcula a completude do perfil de forma síncrona
  int calculateCompletenessSync(User user) {
    int completeness = 0;
    
    // Basic info (30%)
    if (user.userFullname.isNotEmpty) completeness += 10;
    // Calculate age from birth date
    final now = DateTime.now();
    final birthDate = DateTime(user.userBirthYear, user.userBirthMonth, user.userBirthDay);
    final age = now.year - birthDate.year;
    if (age > 0) completeness += 10;
    if (user.userGender.isNotEmpty) completeness += 10;
    
    // Profile photo (20%)
    if (user.userProfilePhoto.isNotEmpty) completeness += 20;
    
    // Gallery (20%)
    if (user.userGallery != null && user.userGallery!.isNotEmpty) {
      completeness += 20;
    }
    
    // Bio (15%)
    if (user.userBio.isNotEmpty) completeness += 15;
    
    // Location (15%)
    if (user.userLocality.isNotEmpty && 
        (user.userState?.isNotEmpty ?? false)) {
      completeness += 15;
    }
    
    return completeness.clamp(0, 100);
  }

  /// Verifica se deve mostrar diálogo de completude
  Future<void> maybeShow({required BuildContext context}) async {
    // TODO: Implementar lógica de exibição do diálogo
    // Por agora, não faz nada
  }
}