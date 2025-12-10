import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partiu/shared/repositories/auth_repository.dart';
import 'package:partiu/features/profile/presentation/models/edit_profile_models.dart';
import 'package:partiu/features/profile/presentation/models/edit_profile_commands.dart';
import 'package:partiu/shared/stores/avatar_store.dart';

/// ViewModel para EditProfileScreen seguindo padrão MVVM com Command Pattern
/// 
/// Responsabilidades:
/// - Gerenciar estado da tela (loading, loaded, saving, error)
/// - Validar dados do formulário com funções puras
/// - Retornar Commands para a View executar
/// - Isolar lógica de negócio da UI
/// - Coordenar operações entre repositories
/// - Expor propriedades derivadas do estado (currentUser)
/// 
/// Segue boas práticas:
/// - [OK] Separação de preocupações
/// - [OK] Não depende de BuildContext
/// - [OK] Usa Command Pattern explícito
/// - [OK] Gerencia estado com ChangeNotifier
/// - [OK] Modelos imutáveis
/// - [OK] Testável independentemente da UI
/// - [OK] Fluxo unidirecional de dados
/// - [OK] Usa AuthRepository para abstrair acesso ao usuário atual
/// - [OK] Não gerencia Controllers (responsabilidade da View)
/// - [OK] Não gerencia FormKey (responsabilidade da View)
/// - [OK] Trabalha apenas com dados puros (Strings, ints, etc)
class EditProfileViewModelRefactored extends ChangeNotifier {
  
  // ==================== CONSTRUCTOR ====================
  
  EditProfileViewModelRefactored({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository;
  
  final AuthRepository _authRepository;
  
  // ==================== STATE ====================
  
  EditProfileState _state = const EditProfileStateInitial();
  EditProfileState get state => _state;
  
  EditProfileCommand? _lastCommand;
  EditProfileCommand? get lastCommand => _lastCommand;
  
  // Campo privado para manter selectedTabIndex independente do estado
  int _selectedTabIndex = 0;
  
  bool get isLoading => _state is EditProfileStateSaving || 
                        _state is EditProfileStateUpdatingPhoto;
  
  bool get isInitial => _state is EditProfileStateInitial;
  
  bool get hasError => _state is EditProfileStateError;
  
  /// URL da foto de perfil atual
  String get currentPhotoUrl => _authRepository.currentUser?.photoUrl ?? '';
  
  /// ID do usuário atual
  String get userId => _authRepository.currentUser?.userId ?? '';
  
  /// Nome completo do usuário atual
  String get userFullname => _authRepository.currentUser?.fullName ?? '';
  
  /// Obtém índice da tab selecionada
  int get selectedTabIndex => _selectedTabIndex;
  
  /// Método auxiliar para criar EditProfileStateLoaded mantendo sincronização
  EditProfileStateLoaded _createLoadedState({
    required ProfileFormData formData,
    bool hasUnsavedChanges = false,
    int? selectedTabIndex,
  }) {
    // Se selectedTabIndex for passado, sincroniza o campo privado
    if (selectedTabIndex != null) {
      _selectedTabIndex = selectedTabIndex;
    }
    
    return EditProfileStateLoaded(
      formData: formData,
      hasUnsavedChanges: hasUnsavedChanges,
      selectedTabIndex: _selectedTabIndex,
    );
  }
  
  // ==================== INITIALIZATION ====================
  
  /// Carrega dados iniciais do perfil
  /// Busca dados frescos do Firestore para garantir sincronização
  Future<void> loadProfileData() async {
    _state = const EditProfileStateInitial();
    notifyListeners();
    
    try {
      // Busca dados frescos do Firestore ao invés de usar dados em memória
      final currentUser = await _authRepository.fetchCurrentUserFromFirestore();
      
      if (currentUser == null) {
        throw Exception('user_not_found');
      }
      
      // Construir ProfileFormData a partir do usuário atual
      final formData = ProfileFormData(
        fullname: currentUser.fullName,
        bio: currentUser.bio ?? '',
        jobTitle: currentUser.jobTitle ?? '',
        gender: currentUser.gender,
        birthDay: currentUser.birthDay,
        birthMonth: currentUser.birthMonth,
        birthYear: currentUser.birthYear,
        locality: currentUser.locality ?? '',
        state: currentUser.state ?? '',
        country: currentUser.from ?? '', // País de origem
        locationCountry: currentUser.country ?? '', // País da localização atual
        instagram: currentUser.instagram ?? '',
        // ✅ CRÍTICO: Converter array de interesses para string CSV para compatibilidade com UI
        // Ex: ["Fotografia", "Videografia"] -> "Fotografia,Videografia"
        interests: currentUser.interests?.join(',') ?? '',
        languages: currentUser.languages ?? '',
      );
      
      _state = _createLoadedState(formData: formData);
      notifyListeners();
      
    } catch (e) {
      _state = EditProfileStateError(
        message: e.toString(),
        formData: const ProfileFormData(),
      );
      notifyListeners();
    }
  }
  
  /// Seleciona tab por índice
  void selectTab(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      
      // Atualiza o estado se estiver carregado
      if (_state is EditProfileStateLoaded) {
        final currentState = _state as EditProfileStateLoaded;
        _state = _createLoadedState(
          formData: currentState.formData,
          hasUnsavedChanges: currentState.hasUnsavedChanges,
          selectedTabIndex: index,
        );
      }
      
      notifyListeners();
    }
  }

  /// Atualiza a lista de ofertas no estado atual
  void updateOffers(List<Offer> offers) {
    if (_state is EditProfileStateLoaded) {
      final current = _state as EditProfileStateLoaded;
      final updated = current.formData.copyWith(offers: offers);
      _state = _createLoadedState(
        formData: updated,
        hasUnsavedChanges: true,
      );
      notifyListeners();
    }
  }
  
  // ==================== FIELD UPDATES ====================
  
  /// Atualiza campo individual do formulário
  /// Mantém mudanças localmente até o usuário clicar em Save
  void updateField(String fieldName, dynamic value) {
    if (_state is! EditProfileStateLoaded) return;
    
    final current = _state as EditProfileStateLoaded;
    ProfileFormData updated;
    
    switch (fieldName) {
      case 'fullname':
        updated = current.formData.copyWith(fullname: value as String?);
      case 'bio':
        updated = current.formData.copyWith(bio: value as String);
      case 'jobTitle':
        updated = current.formData.copyWith(jobTitle: value as String);
      case 'school':
        updated = current.formData.copyWith(school: value as String);
      case 'gender':
        updated = current.formData.copyWith(gender: value as String?);
      case 'birthDay':
        updated = current.formData.copyWith(birthDay: value as int?);
      case 'birthMonth':
        updated = current.formData.copyWith(birthMonth: value as int?);
      case 'birthYear':
        updated = current.formData.copyWith(birthYear: value as int?);
      case 'phoneNumber':
        updated = current.formData.copyWith(phoneNumber: value as String?);
      case 'email':
        updated = current.formData.copyWith(email: value as String?);
      case 'website':
        updated = current.formData.copyWith(website: value as String?);
      case 'instagram':
        updated = current.formData.copyWith(instagram: value as String?);
      case 'vimeo':
        updated = current.formData.copyWith(vimeo: value as String?);
      case 'tiktok':
        updated = current.formData.copyWith(tiktok: value as String?);
      case 'pinterest':
        updated = current.formData.copyWith(pinterest: value as String?);
      case 'youtube':
        updated = current.formData.copyWith(youtube: value as String?);
      case 'locality':
        updated = current.formData.copyWith(locality: value as String?);
      case 'state':
        updated = current.formData.copyWith(state: value as String?);
      case 'country':
        updated = current.formData.copyWith(country: value as String?);
      case 'interests':
        updated = current.formData.copyWith(interests: value as String?);
      default:
        return; // Campo desconhecido, não faz nada
    }
    
    _state = _createLoadedState(
      formData: updated,
      hasUnsavedChanges: true,
    );
    notifyListeners();
  }
  
  // ==================== VALIDATION ====================
  
  /// Valida formulário baseado nos requisitos do Partiu
  /// 
  /// Campos obrigatórios:
  /// - Bio obrigatório
  ValidationResult validateForm(ProfileFormData data) {
    final errors = <String, String>{};
    
    // Bio é obrigatório
    if (data.bio.trim().isEmpty) {
      errors['bio'] = 'bio_required';
    }
    
    // Validação de email se preenchido
    if (data.email != null && data.email!.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(data.email!)) {
        errors['email'] = 'invalid_email';
      }
    }
    
    return errors.isEmpty
        ? const ValidationResultValid()
        : ValidationResultInvalid(fieldErrors: errors);
  }
  
  /// Valida campo específico
  String? validateField(String fieldName, String? value) {
    if (value == null || value.trim().isEmpty) {
      return switch (fieldName) {
        'bio' => 'bio_required',
        _ => null,
      };
    }
    
    // Validações específicas por campo
    return switch (fieldName) {
      'email' => _validateEmail(value),
      _ => null,
    };
  }
  
  String? _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'invalid_email';
    }
    return null;
  }
  
  // ==================== SAVE PROFILE ====================
  
  /// Processa salvamento do perfil
  /// Retorna SaveResult para View processar
  Future<SaveResult> handleSaveProfile(ProfileFormData data) async {
    if (isLoading) {
      return const SaveResultFailure(messageKey: 'operation_in_progress');
    }
    
    // Validação dos dados
    final validation = validateForm(data);
    if (validation is ValidationResultInvalid) {
      _lastCommand = ValidationFailedCommand(
        fieldErrors: validation.fieldErrors,
      );
      notifyListeners();
      
      return const SaveResultFailure(messageKey: 'validation_failed');
    }
    
    // Iniciar salvamento
    _state = EditProfileStateSaving(formData: data);
    _lastCommand = null;
    notifyListeners();
    
    try {
      final userId = _authRepository.currentUser?.userId;
      
      if (userId == null || userId.isEmpty) {
        throw Exception('user_id_not_found');
      }
      
      // Criar mapa com os dados atualizados usando os nomes de campo modernos
      final updateData = <String, dynamic>{};
      
      if (data.fullname != null) updateData['fullName'] = data.fullname!.trim();
      if (data.bio.isNotEmpty) updateData['bio'] = data.bio.trim();
      if (data.jobTitle.isNotEmpty) updateData['jobTitle'] = data.jobTitle.trim();
      if (data.school.isNotEmpty) updateData['school'] = data.school.trim();
      if (data.gender != null) updateData['gender'] = data.gender;
      if (data.birthDay != null) updateData['birthDay'] = data.birthDay;
      if (data.birthMonth != null) updateData['birthMonth'] = data.birthMonth;
      if (data.birthYear != null) updateData['birthYear'] = data.birthYear;
      if (data.locality != null && data.locality!.isNotEmpty) {
        updateData['locality'] = data.locality!.trim();
      }
      if (data.state != null && data.state!.isNotEmpty) {
        updateData['state'] = data.state!.trim();
      }
      if (data.country != null && data.country!.isNotEmpty) {
        updateData['from'] = data.country!.trim();
      }
      if (data.email != null && data.email!.isNotEmpty) {
        updateData['email'] = data.email!.trim();
      }
      if (data.phoneNumber != null && data.phoneNumber!.isNotEmpty) {
        updateData['phoneNumber'] = data.phoneNumber!.trim();
      }
      if (data.website != null && data.website!.isNotEmpty) {
        updateData['website'] = data.website!.trim();
      }
      if (data.instagram != null && data.instagram!.isNotEmpty) {
        updateData['instagram'] = data.instagram!.trim();
      }
      if (data.tiktok != null && data.tiktok!.isNotEmpty) {
        updateData['tiktok'] = data.tiktok!.trim();
      }
      if (data.youtube != null && data.youtube!.isNotEmpty) {
        updateData['youtube'] = data.youtube!.trim();
      }
      if (data.pinterest != null && data.pinterest!.isNotEmpty) {
        updateData['pinterest'] = data.pinterest!.trim();
      }
      if (data.vimeo != null && data.vimeo!.isNotEmpty) {
        updateData['vimeo'] = data.vimeo!.trim();
      }
      if (data.interests != null && data.interests!.isNotEmpty) {
        // ✅ CRÍTICO: Converter string CSV para array para cálculo correto de completude
        // Ex: "Fotografia,Videografia" -> ["Fotografia", "Videografia"]
        final interestsList = data.interests!
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        updateData['interests'] = interestsList;
      }
      if (data.languages != null && data.languages!.isNotEmpty) {
        updateData['languages'] = data.languages!.trim();
      }
      
      // Atualizar perfil via AuthRepository
      await _authRepository.updateUserProfile(updateData);
      
      // ✅ CRÍTICO: Recarregar dados atualizados do Firestore
      // Isso atualiza SessionManager e AppState.currentUser
      // Permitindo que ProfileTab recalcule a completude em tempo real
      await _authRepository.fetchCurrentUserFromFirestore();
      
      // Sucesso
      _lastCommand = SaveProfileSuccessCommand();
      _state = EditProfileStateLoaded(
        formData: data,
        selectedTabIndex: selectedTabIndex,
      );
      notifyListeners();
      
      return const SaveResultSuccess();
      
    } catch (e) {
      final errorCommand = SaveProfileErrorCommand(
        messageKey: 'save_profile_error',
        errorDetails: e.toString(),
      );
      
      _lastCommand = errorCommand;
      _state = EditProfileStateError(
        message: e.toString(),
        formData: data,
      );
      notifyListeners();
      
      return SaveResultFailure(
        messageKey: 'save_profile_error',  
        errorDetails: e.toString(),
      );
    }
  }
  
  // ==================== UPDATE PHOTO ====================
  
  /// Processa atualização de foto de perfil (avatar)
  /// Com seleção de imagem, compressão e upload
  Future<PhotoUploadResult> handleUpdateProfilePhoto() async {
    if (isLoading) {
      return const PhotoUploadResultFailure(messageKey: 'operation_in_progress');
    }
    
    final currentData = _getCurrentFormData();
    
    try {
      // 1. Selecionar imagem da galeria
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      
      if (picked == null) {
        // Usuário cancelou seleção
        return const PhotoUploadResultFailure(messageKey: 'image_selection_cancelled');
      }
      
      final originalFile = File(picked.path);
      
      // Validar tamanho da imagem (15MB)
      final imageSize = await originalFile.length();
      const maxImageSize = 15 * 1024 * 1024;
      if (imageSize > maxImageSize) {
        final sizeMB = (imageSize / (1024 * 1024)).toStringAsFixed(1);
        return PhotoUploadResultFailure(
          messageKey: 'image_too_large',
          errorDetails: 'Imagem muito grande (${sizeMB}MB). Máximo permitido: 15MB.',
        );
      }
      
      // 2. Iniciar estado de upload (mostra spinner)
      _state = EditProfileStateUpdatingPhoto(formData: currentData);
      _lastCommand = null;
      notifyListeners();
      
      // 3. Upload da foto via AuthRepository (que faz compressão automática)
      final newPhotoUrl = await _authRepository.uploadProfilePhoto(originalFile);
      
      // 4. Recarregar dados atualizados do Firestore após upload de foto
      await _authRepository.fetchCurrentUserFromFirestore();
      
      // ✅ CRÍTICO: Invalidar cache de avatar para forçar reload da imagem
      final userId = _authRepository.currentUser?.userId;
      if (userId != null && userId.isNotEmpty) {
        AvatarStore.instance.invalidateAndReload(userId);
      }
      
      _lastCommand = UpdatePhotoSuccessCommand(newPhotoUrl: newPhotoUrl);
      _state = EditProfileStateLoaded(formData: currentData);
      notifyListeners();
      
      return PhotoUploadResultSuccess(photoUrl: newPhotoUrl);
      
    } catch (e) {
      final errorCommand = UpdatePhotoErrorCommand(
        messageKey: 'update_photo_error',
        errorDetails: e.toString(),
      );
      
      _lastCommand = errorCommand;
      _state = EditProfileStateError(
        message: e.toString(),
        formData: currentData,
      );
      notifyListeners();
      
      return PhotoUploadResultFailure(
        messageKey: 'update_photo_error',
        errorDetails: e.toString(),
      );
    }
  }
  
  /// Processa atualização de foto (método legacy mantido para compatibilidade)
  /// Retorna PhotoUploadResult para View processar
  /// Emite Commands via lastCommand
  Future<PhotoUploadResult> handleUpdatePhoto(File imageFile) async {
    if (isLoading) {
      return const PhotoUploadResultFailure(messageKey: 'operation_in_progress');
    }
    
    final currentData = _getCurrentFormData();
    _state = EditProfileStateUpdatingPhoto(formData: currentData);
    _lastCommand = null;
    notifyListeners();
    
    try {
      if (!await imageFile.exists()) {
        throw Exception('file_not_found');
      }
      
      // Upload da foto via AuthRepository
      final newPhotoUrl = await _authRepository.uploadProfilePhoto(imageFile);
      
      // ✅ CRÍTICO: Recarregar dados atualizados do Firestore após upload de foto
      // Isso atualiza SessionManager e AppState.currentUser com a nova foto
      // Permitindo que ProfileTab e ProfileCompletenessRing atualizem em tempo real
      await _authRepository.fetchCurrentUserFromFirestore();
      
      // ✅ CRÍTICO: Invalidar cache de avatar para forçar reload da imagem
      final userId = _authRepository.currentUser?.userId;
      if (userId != null && userId.isNotEmpty) {
        AvatarStore.instance.invalidateAndReload(userId);
      }
      
      _lastCommand = UpdatePhotoSuccessCommand(newPhotoUrl: newPhotoUrl);
      _state = EditProfileStateLoaded(formData: currentData);
      notifyListeners();
      
      return PhotoUploadResultSuccess(photoUrl: newPhotoUrl);
      
    } catch (e) {
      final errorCommand = UpdatePhotoErrorCommand(
        messageKey: 'update_photo_error',
        errorDetails: e.toString(),
      );
      
      _lastCommand = errorCommand;
      _state = EditProfileStateError(
        message: e.toString(),
        formData: currentData,
      );
      notifyListeners();
      
      return PhotoUploadResultFailure(
        messageKey: 'update_photo_error',
        errorDetails: e.toString(),
      );
    }
  }
  
  // ==================== HELPERS ====================
  
  /// Marca que há mudanças não salvas
  void markAsUnsaved() {
    if (_state is EditProfileStateLoaded) {
      final loadedState = _state as EditProfileStateLoaded;
      _state = EditProfileStateLoaded(
        formData: loadedState.formData,
        hasUnsavedChanges: true,
        selectedTabIndex: loadedState.selectedTabIndex,
      );
      notifyListeners();
    }
  }
  
  /// Atualiza um campo específico do formulário
  void updateFormField(String fieldName, dynamic value) {
    final currentData = _getCurrentFormData();
    
    final updatedData = switch (fieldName) {
      'fullname' => currentData.copyWith(fullname: value as String?),
      'bio' => currentData.copyWith(bio: value as String),
      'jobTitle' => currentData.copyWith(jobTitle: value as String),
      'school' => currentData.copyWith(school: value as String),
      'gender' => currentData.copyWith(gender: value as String?),
      'email' => currentData.copyWith(email: value as String?),
      'phoneNumber' => currentData.copyWith(phoneNumber: value as String?),
      'website' => currentData.copyWith(website: value as String?),
      'instagram' => currentData.copyWith(instagram: value as String?),
      'locality' => currentData.copyWith(locality: value as String?),
      'state' => currentData.copyWith(state: value as String?),
      'country' => currentData.copyWith(country: value as String?),
      'interests' => currentData.copyWith(interests: value as String?),
      _ => currentData,
    };
    
    _state = EditProfileStateLoaded(
      formData: updatedData,
      hasUnsavedChanges: true,
      selectedTabIndex: selectedTabIndex,
    );
    notifyListeners();
  }
  
  /// Limpa o último comando processado
  /// Deve ser chamado pela View após processar o comando
  void clearCommand() {
    _lastCommand = null;
    // Não notifica listeners para evitar rebuild desnecessário
  }
  
  /// Obtém os dados atuais do formulário independente do estado
  ProfileFormData _getCurrentFormData() {
    return switch (_state) {
      EditProfileStateLoaded(:final formData) => formData,
      EditProfileStateSaving(:final formData) => formData,
      EditProfileStateUpdatingPhoto(:final formData) => formData,
      EditProfileStateError(:final formData) => formData,
      _ => const ProfileFormData(),
    };
  }
  
  /// Reseta estado para inicial
  void reset() {
    _state = const EditProfileStateInitial();
    _lastCommand = null;
    _selectedTabIndex = 0;
    notifyListeners();
  }
}