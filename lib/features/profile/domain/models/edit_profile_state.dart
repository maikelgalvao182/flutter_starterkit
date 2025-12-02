/// Estados do EditProfile
abstract class EditProfileState {
  const EditProfileState();
}

/// Estado inicial (antes de carregar dados)
class EditProfileStateInitial extends EditProfileState {
  const EditProfileStateInitial();
}

/// Estado carregando dados
class EditProfileStateLoading extends EditProfileState {
  const EditProfileStateLoading();
}

/// Estado carregado (dados prontos para edição)
class EditProfileStateLoaded extends EditProfileState {
  final Map<String, dynamic> formData;
  final bool hasUnsavedChanges;
  
  const EditProfileStateLoaded({
    required this.formData,
    this.hasUnsavedChanges = false,
  });
}

/// Estado salvando
class EditProfileStateSaving extends EditProfileState {
  const EditProfileStateSaving();
}

/// Estado erro
class EditProfileStateError extends EditProfileState {
  final String message;
  
  const EditProfileStateError(this.message);
}

// ==================== COMMANDS ====================

/// Commands para ações do EditProfile
abstract class EditProfileCommand {}

/// Sucesso ao salvar perfil
class SaveProfileSuccessCommand extends EditProfileCommand {
  final String message;
  SaveProfileSuccessCommand(this.message);
}

/// Erro ao salvar perfil
class SaveProfileErrorCommand extends EditProfileCommand {
  final String message;
  SaveProfileErrorCommand(this.message);
}

/// Sucesso ao atualizar foto
class UpdatePhotoSuccessCommand extends EditProfileCommand {
  final String newPhotoUrl;
  UpdatePhotoSuccessCommand(this.newPhotoUrl);
}

/// Erro ao atualizar foto
class UpdatePhotoErrorCommand extends EditProfileCommand {
  final String message;
  UpdatePhotoErrorCommand(this.message);
}
