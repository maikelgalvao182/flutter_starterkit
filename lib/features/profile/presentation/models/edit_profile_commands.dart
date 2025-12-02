/// Commands para EditProfile Module
/// 
/// Seguindo Command Pattern:
/// - Commands são objetos imutáveis que representam intenções
/// - A View interpreta e executa os Commands
/// - ViewModel apenas valida e retorna Commands
library;

/// Command base para ações da tela de edição de perfil
abstract class EditProfileCommand {}

/// Command: Salvar perfil com sucesso
class SaveProfileSuccessCommand extends EditProfileCommand {
  SaveProfileSuccessCommand({
    this.messageKey = 'profile_updated_successfully',
  });
  
  final String messageKey;
}

/// Command: Erro ao salvar perfil
class SaveProfileErrorCommand extends EditProfileCommand {
  SaveProfileErrorCommand({
    required this.messageKey,
    this.errorDetails,
  });
  
  final String messageKey;
  final String? errorDetails;
}

/// Command: Atualizar foto com sucesso
class UpdatePhotoSuccessCommand extends EditProfileCommand {
  UpdatePhotoSuccessCommand({
    required this.newPhotoUrl,
    this.messageKey = 'photo_updated_successfully',
  });
  
  final String newPhotoUrl;
  final String messageKey;
}

/// Command: Erro ao atualizar foto
class UpdatePhotoErrorCommand extends EditProfileCommand {
  UpdatePhotoErrorCommand({
    required this.messageKey,
    this.errorDetails,
  });
  
  final String messageKey;
  final String? errorDetails;
}

/// Command: Mostrar feedback ao usuário
class ShowFeedbackCommand extends EditProfileCommand {
  ShowFeedbackCommand({
    required this.messageKey,
    this.isError = false,
    this.isSuccess = false,
  });
  
  final String messageKey;
  final bool isError;
  final bool isSuccess;
}

/// Command: Navegar de volta (após salvar com sucesso)
class NavigateBackCommand extends EditProfileCommand {
  NavigateBackCommand({
    this.shouldRefresh = true,
  });
  
  final bool shouldRefresh;
}

/// Command: Solicitar seleção de imagem
class RequestImageSelectionCommand extends EditProfileCommand {
  RequestImageSelectionCommand({
    required this.source,
  });
  
  final ImageSelectionSource source;
}

/// Source para seleção de imagem
enum ImageSelectionSource {
  camera,
  gallery,
}

/// Command: Validação falhou
class ValidationFailedCommand extends EditProfileCommand {
  ValidationFailedCommand({
    required this.fieldErrors,
    this.messageKey = 'please_fill_required_fields',
  });
  
  final Map<String, String> fieldErrors;
  final String messageKey;
}

/// Command: Abrir seletor de localização
class OpenLocationPickerCommand extends EditProfileCommand {
  OpenLocationPickerCommand({
    this.currentLocation,
  });
  
  final String? currentLocation;
}

/// Command: Abrir seletor de país
class OpenCountryPickerCommand extends EditProfileCommand {
  OpenCountryPickerCommand({
    this.currentCountry,
  });
  
  final String? currentCountry;
}

/// Command: Confirmar alterações não salvas
class ConfirmUnsavedChangesCommand extends EditProfileCommand {
  ConfirmUnsavedChangesCommand({
    required this.onConfirm,
  });
  
  final VoidCallback onConfirm;
}

/// VoidCallback type
typedef VoidCallback = void Function();