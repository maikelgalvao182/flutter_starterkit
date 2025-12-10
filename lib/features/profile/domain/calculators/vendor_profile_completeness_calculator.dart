import 'package:partiu/core/models/user.dart';
import 'package:partiu/features/profile/domain/calculators/i_profile_completeness_calculator.dart';
import 'package:partiu/core/utils/app_logger.dart';

/// Calculadora de completude específica para Fornecedores (Vendors)
/// 
/// Avalia completude baseado em:
/// - Personal Tab: Avatar, Nome, Bio, Gênero, Data de Nascimento, Localização, País, Idiomas, Instagram, Job Title
/// - Interests Tab: Interesses selecionados
/// - Gallery Tab: Fotos da galeria
class VendorProfileCompletenessCalculator implements IProfileCompletenessCalculator {
  static const String _tag = 'VendorCompletenessCalc';
  
  // Pesos definidos para Vendor (Total: 100)
  // PERSONAL TAB (70 pontos)
  static const int _avatarW = 15;           // Obrigatório
  static const int _nameW = 10;             // Obrigatório
  static const int _bioW = 10;              // Obrigatório
  static const int _genderW = 5;            // Obrigatório
  static const int _birthDateW = 5;         // Obrigatório
  static const int _locationW = 5;          // Localização (locality)
  static const int _countryW = 5;           // País
  static const int _languagesW = 5;         // Idiomas
  static const int _instagramW = 5;         // Instagram
  static const int _jobTitleW = 5;          // Profissão
  
  // INTERESTS TAB (15 pontos)
  static const int _interestsWMax = 15;    // Máximo de 15 pontos (progressivo)
  
  // GALLERY TAB (15 pontos)
  static const int _photosWMax = 15;        // Máximo de 15 pontos (progressivo)

  @override
  int calculate(User user) {
    int score = 0;
    
    // === PERSONAL TAB ===
    // 1. Avatar (15)
    if (user.photoUrl.isNotEmpty) {
      score += _avatarW;
    } else {
      AppLogger.debug('Missing Avatar', tag: _tag);
    }
    
    // 2. Nome (10)
    if (user.userFullname.isNotEmpty) {
      score += _nameW;
    } else {
      AppLogger.debug('Missing Name', tag: _tag);
    }
    
    // 3. Bio (10)
    if (user.userBio.isNotEmpty) {
      score += _bioW;
    } else {
      AppLogger.debug('Missing Bio', tag: _tag);
    }
    
    // 4. Gênero (5)
    if (user.userGender.isNotEmpty) {
      score += _genderW;
    } else {
      AppLogger.debug('Missing Gender', tag: _tag);
    }
    
    // 5. Data de Nascimento (5)
    if (user.userBirthDay > 0 && user.userBirthMonth > 0 && user.userBirthYear > 0) {
      score += _birthDateW;
    } else {
      AppLogger.debug('Missing Birth Date', tag: _tag);
    }
    
    // 6. Localização (5)
    final hasLocation = user.userLocality.isNotEmpty || ((user.userState ?? '').isNotEmpty);
    if (hasLocation) {
      score += _locationW;
    } else {
      AppLogger.debug('Missing Location', tag: _tag);
    }
    
    // 7. País (5)
    if (user.userCountry.isNotEmpty) {
      score += _countryW;
    } else {
      AppLogger.debug('Missing Country', tag: _tag);
    }
    
    // 8. Idiomas (5)
    if (user.languages != null && user.languages!.isNotEmpty) {
      score += _languagesW;
    } else {
      AppLogger.debug('Missing Languages', tag: _tag);
    }
    
    // 9. Instagram (5)
    if (user.userInstagram != null && user.userInstagram!.isNotEmpty) {
      score += _instagramW;
    } else {
      AppLogger.debug('Missing Instagram', tag: _tag);
    }
    
    // 10. Job Title (5)
    if (user.userJobTitle.isNotEmpty) {
      score += _jobTitleW;
    } else {
      AppLogger.debug('Missing Job Title', tag: _tag);
    }
    
    // === INTERESTS TAB ===
    // 11. Interesses (Max 15) - Progressivo
    score += _calculateInterestsScore(user);
    
    // === GALLERY TAB ===
    // 12. Photos (Max 15) - Progressivo
    score += _calculatePhotosScore(user);
    
    AppLogger.info('Total Score: $score%', tag: _tag);
    return score.clamp(0, 100);
  }
  
  int _calculateInterestsScore(User user) {
    final interests = user.interests ?? [];
    final count = interests.length;
    
    // 1.5 pontos por interesse até 10 interesses (Max 15)
    final score = (count * 1.5).round().clamp(0, _interestsWMax);
    
    if (count == 0) {
      AppLogger.debug('Missing Interests', tag: _tag);
    } else {
      AppLogger.debug('Interests: $count items = $score points', tag: _tag);
    }
    
    return score;
  }
  
  int _calculatePhotosScore(User user) {
    final gallery = user.userGallery ?? <String, dynamic>{};
    final photoCount = gallery.values.where((v) {
      if (v == null) return false;
      if (v is String) return v.trim().isNotEmpty;
      if (v is Map<String, dynamic>) {
        final url = v['url'] as String?;
        return url != null && url.trim().isNotEmpty;
      }
      return false;
    }).length;
    
    // ✅ GALERIA: Máximo de 9 fotos (UserImagesGrid: List<bool>.filled(9, false))
    // Cálculo progressivo: 15 pontos / 9 fotos = ~1.67 pontos por foto
    // Exemplos: 3 fotos = 5pts, 6 fotos = 10pts, 9 fotos = 15pts
    final score = ((photoCount * _photosWMax) / 9).round().clamp(0, _photosWMax);
    
    if (photoCount == 0) {
      AppLogger.debug('Missing Gallery Photos', tag: _tag);
    } else {
      AppLogger.debug('Gallery: $photoCount photos = $score points', tag: _tag);
    }
    
    return score;
  }

  @override
  Map<String, dynamic> getDetails(User user) {
    final hasLocation = user.userLocality.isNotEmpty || ((user.userState ?? '').isNotEmpty);
    final hasBirth = user.userBirthDay > 0 && user.userBirthMonth > 0 && user.userBirthYear > 0;
    final hasLanguages = user.languages != null && user.languages!.isNotEmpty;
    final hasInstagram = user.userInstagram != null && user.userInstagram!.isNotEmpty;
    
    final details = {
      // Personal Tab
      'avatar': user.photoUrl.isNotEmpty ? _avatarW : 0,
      'name': user.userFullname.isNotEmpty ? _nameW : 0,
      'bio': user.userBio.isNotEmpty ? _bioW : 0,
      'gender': user.userGender.isNotEmpty ? _genderW : 0,
      'birthDate': hasBirth ? _birthDateW : 0,
      'location': hasLocation ? _locationW : 0,
      'country': user.userCountry.isNotEmpty ? _countryW : 0,
      'languages': hasLanguages ? _languagesW : 0,
      'instagram': hasInstagram ? _instagramW : 0,
      'jobTitle': user.userJobTitle.isNotEmpty ? _jobTitleW : 0,
      
      // Interests Tab
      'interests': _calculateInterestsScore(user),
      
      // Gallery Tab
      'photos': _calculatePhotosScore(user),
    };
    
    final total = calculate(user);
    AppLogger.info('Details: $details -> TOTAL: $total%', tag: _tag);
    
    return details;
  }
}
