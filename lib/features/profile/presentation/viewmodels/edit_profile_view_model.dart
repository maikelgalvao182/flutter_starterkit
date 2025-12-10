import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/services/auth_state_service.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/managers/session_manager.dart';
import 'package:partiu/core/models/user.dart' as app_user;
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/features/profile/domain/models/edit_profile_state.dart';
import 'package:partiu/features/profile/domain/models/profile_form_data.dart';
import 'package:partiu/features/profile/domain/repositories/profile_repository_interface.dart';
import 'package:partiu/core/services/image_picker_service.dart';
import 'package:partiu/features/profile/domain/models/photo_upload_models.dart';

/// ViewModel para EditProfileScreen seguindo padrão MVVM
/// 
/// Responsabilidades:
/// - Gerenciar estado da tela de edição
/// - Carregar dados do perfil
/// - Validar e salvar alterações
/// - Gerenciar upload de fotos
/// - Emitir commands para a View executar (toast, navegação)
/// 
/// Segue boas práticas:
/// - Não depende de BuildContext
/// - Estado imutável (ProfileFormData)
/// - Commands para separar lógica de UI
/// - Injeção de dependências
class EditProfileViewModel extends ChangeNotifier {
  final IProfileRepository _profileRepository;
  final FirebaseFirestore _firestore;
  final ImagePickerService _imagePickerService;
  
  EditProfileViewModel({
    required IProfileRepository profileRepository,
    FirebaseFirestore? firestore,
    ImagePickerService? imagePickerService,
  })  : _profileRepository = profileRepository,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _imagePickerService = imagePickerService ?? ImagePickerService();
  
  static const String _tag = 'EditProfileViewModel';
  
  // ==================== STATE ====================
  
  EditProfileState _state = const EditProfileStateInitial();
  EditProfileState get state => _state;
  
  EditProfileCommand? _lastCommand;
  EditProfileCommand? get lastCommand => _lastCommand;
  
  ProfileFormData? _originalData;
  ProfileFormData? _currentData;
  
  bool get isLoading => _state is EditProfileStateLoading || 
                        _state is EditProfileStateSaving;
  
  bool get hasUnsavedChanges {
    if (_state is! EditProfileStateLoaded) return false;
    return (_state as EditProfileStateLoaded).hasUnsavedChanges;
  }
  
  String? get userId {
    // Usa AuthStateService como fonte primária
    final authId = AuthStateService.instance.userId;
    if (authId != null && authId.isNotEmpty) return authId;

    // Fallback para SessionManager
    final sessionUser = SessionManager.instance.currentUser;
    final sessionId = sessionUser?.userId;
    if (sessionId != null && sessionId.isNotEmpty) {
      AppLogger.warning(
        'AuthStateService returned null, using SessionManager user: $sessionId', 
        tag: _tag,
      );
      return sessionId;
    }

    return null;
  }
  
  // ==================== PUBLIC METHODS ====================
  
  /// Carrega dados do perfil para edição
  Future<void> loadProfileData() async {
    final currentUserId = userId;
    if (currentUserId == null) {
      _emitError('Usuário não autenticado');
      return;
    }
    
    try {
      _setState(const EditProfileStateLoading());
      AppLogger.info('Loading profile data...', tag: _tag);
      
      Map<String, dynamic>? data;
      try {
        data = await _profileRepository.fetchProfileData(currentUserId);
      } catch (e) {
        // Retry logic for permission-denied errors during initialization
        // Se falhar por permissão e o AuthStateService ainda estiver null (mas temos currentUserId local),
        // esperamos um pouco pela inicialização do Firebase Auth.
        if (e.toString().contains('permission-denied') && AuthStateService.instance.userId == null) {
          AppLogger.warning('Permission denied. Waiting for Firebase Auth initialization...', tag: _tag);
          await Future.delayed(const Duration(seconds: 2));
          
          if (AuthStateService.instance.userId != null) {
             AppLogger.info('Firebase Auth initialized. Retrying fetch...', tag: _tag);
             data = await _profileRepository.fetchProfileData(currentUserId);
          } else {
             rethrow;
          }
        } else {
          rethrow;
        }
      }
      
      if (data == null) {
        _emitError('Perfil não encontrado');
        return;
      }
      
      _originalData = ProfileFormData.fromFirestore(data);
      _currentData = _originalData;
      
      _setState(EditProfileStateLoaded(
        formData: data,
        hasUnsavedChanges: false,
      ));
      
      AppLogger.info('Profile data loaded successfully', tag: _tag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error loading profile data: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      _emitError('Erro ao carregar perfil');
    }
  }
  
  /// Atualiza um campo específico do formulário
  void updateField(String fieldName, dynamic value) {
    if (_currentData == null) return;
    
    // Cria novo ProfileFormData com campo atualizado
    ProfileFormData updatedData;
    
    switch (fieldName) {
      case 'fullname':
        updatedData = _currentData!.copyWith(fullname: value as String?);
      case 'bio':
        updatedData = _currentData!.copyWith(bio: value as String?);
      case 'jobTitle':
        updatedData = _currentData!.copyWith(jobTitle: value as String?);
      case 'gender':
        updatedData = _currentData!.copyWith(gender: value as String?);
      case 'locality':
        updatedData = _currentData!.copyWith(locality: value as String?);
      case 'instagram':
        updatedData = _currentData!.copyWith(instagram: value as String?);
      case 'startingPrice':
        updatedData = _currentData!.copyWith(startingPrice: value as double?);
      case 'averagePrice':
        updatedData = _currentData!.copyWith(averagePrice: value as double?);
      case 'yearsOfExperience':
        updatedData = _currentData!.copyWith(yearsOfExperience: value as int?);
      case 'servicesOffered':
        updatedData = _currentData!.copyWith(servicesOffered: value as String?);
      case 'offerCategories':
        updatedData = _currentData!.copyWith(offerCategories: value as List<String>?);
      case 'interests':
        updatedData = _currentData!.copyWith(interests: value as List<String>?);
      case 'photoUrl':
        updatedData = _currentData!.copyWith(photoUrl: value as String?);
      default:
        AppLogger.warning('Unknown field: $fieldName', tag: _tag);
        return;
    }
    
    _currentData = updatedData;
    
    // Verifica se há alterações
    final hasChanges = _hasChanges();
    
    if (_state is EditProfileStateLoaded) {
      _setState(EditProfileStateLoaded(
        formData: (_state as EditProfileStateLoaded).formData,
        hasUnsavedChanges: hasChanges,
      ));
    }
  }
  
  /// Salva todas as alterações do perfil
  Future<void> saveProfile() async {
    if (_currentData == null || userId == null) {
      _emitCommand(SaveProfileErrorCommand('Dados inválidos'));
      return;
    }
    
    if (!_hasChanges()) {
      _emitCommand(SaveProfileSuccessCommand('Nenhuma alteração para salvar'));
      return;
    }
    
    try {
      _setState(const EditProfileStateSaving());
      AppLogger.info('Saving profile changes...', tag: _tag);
      
      final dataToSave = _currentData!.toFirestore();
      await _profileRepository.updateProfile(userId!, dataToSave);
      
      // Atualiza AppState para refletir mudanças imediatamente
      await _refreshCurrentUser();
      
      _originalData = _currentData;
      
      final loadedState = _state is EditProfileStateLoaded
          ? (_state as EditProfileStateLoaded)
          : EditProfileStateLoaded(formData: dataToSave);
      
      _setState(EditProfileStateLoaded(
        formData: loadedState.formData,
        hasUnsavedChanges: false,
      ));
      
      _emitCommand(SaveProfileSuccessCommand('Perfil atualizado com sucesso'));
      AppLogger.info('Profile saved successfully', tag: _tag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving profile: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      
      // Volta ao estado loaded com os dados atuais
      if (_state is EditProfileStateSaving && _currentData != null) {
        _setState(EditProfileStateLoaded(
          formData: _currentData!.toFirestore(),
          hasUnsavedChanges: true,
        ));
      }
      
      _emitCommand(SaveProfileErrorCommand('Erro ao salvar perfil'));
    }
  }
  
  /// Seleciona e faz upload de foto de perfil
  /// Método completo que encapsula toda a lógica (igual ao Advanced-Dating)
  Future<PhotoUploadResult> selectAndUploadProfilePhoto() async {
    debugPrint('[$_tag] 🖼️ selectAndUploadProfilePhoto called');
    
    if (isLoading) {
      debugPrint('[$_tag] ⏳ Upload already in progress');
      return const PhotoUploadResultFailure(messageKey: 'operation_in_progress');
    }
    
    if (userId == null) {
      debugPrint('[$_tag] ❌ userId is null');
      _emitCommand(UpdatePhotoErrorCommand('Usuário não autenticado'));
      return const PhotoUploadResultFailure(messageKey: 'user_not_authenticated');
    }
    
    try {
      debugPrint('[$_tag] 📸 Starting image selection...');
      
      // 1. Usar serviço para selecionar e fazer crop
      final photoData = await _imagePickerService.pickAndCropImage(
        oldPhotoUrl: _currentData?.photoUrl ?? '',
        uploadType: PhotoUploadType.profilePicture,
      );
      
      debugPrint('[$_tag] 📸 Image selection result: ${photoData != null}');
      
      // 2. Usuário cancelou
      if (photoData == null) {
        debugPrint('[$_tag] ❌ User cancelled image selection');
        return const PhotoUploadResultFailure(
          messageKey: 'photo_selection_cancelled',
        );
      }
      
      debugPrint('[$_tag] ✅ Image selected: ${photoData.localPath}');
      
      // 3. Fazer upload
      final result = await handleUpdatePhoto(photoData);
      
      return result;
      
    } catch (e, stackTrace) {
      debugPrint('[$_tag] ❌ Error in selectAndUploadProfilePhoto: $e');
      AppLogger.error(
        'Error selecting profile photo: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      
      _emitCommand(UpdatePhotoErrorCommand('Erro ao selecionar foto'));
      
      return PhotoUploadResultFailure(
        messageKey: 'photo_selection_error',
        errorDetails: e.toString(),
      );
    }
  }
  
  /// Processa atualização de foto (método interno)
  Future<PhotoUploadResult> handleUpdatePhoto(PhotoUploadData photoData) async {
    debugPrint('[$_tag] 🚀 handleUpdatePhoto called');
    
    if (isLoading) {
      return const PhotoUploadResultFailure(messageKey: 'operation_in_progress');
    }
    
    // Muda estado para salvando
    _setState(const EditProfileStateSaving());
    
    try {
      debugPrint('[$_tag] 📤 Uploading image file: ${photoData.localPath}');
      
      // Upload via repository (usa o mesmo método existente)
      await _profileRepository.updateProfilePhoto(userId!, photoData.localPath);
      
      debugPrint('[$_tag] ✅ Upload successful');
      
      // Atualiza estado local
      if (_currentData != null) {
        debugPrint('[$_tag] 🔄 Updating local state...');
        _currentData = ProfileFormData.fromFirestore({
          ..._currentData!.toFirestore(),
          'photoUrl': 'updated', // O repository já atualiza a URL
        });
      }
      
      // Atualiza AppState
      debugPrint('[$_tag] 🔄 Refreshing current user...');
      await _refreshCurrentUser();
      
      // Volta ao estado loaded
      if (_currentData != null) {
        _setState(EditProfileStateLoaded(
          formData: _currentData!.toFirestore(),
          hasUnsavedChanges: false,
        ));
      }
      
      final newPhotoUrl = AppState.currentUser.value?.photoUrl ?? '';
      _emitCommand(UpdatePhotoSuccessCommand(newPhotoUrl));
      
      debugPrint('[$_tag] ✅ Profile photo update complete');
      AppLogger.info('Profile photo updated successfully', tag: _tag);
      
      return PhotoUploadResultSuccess(photoUrl: newPhotoUrl);
      
    } catch (e, stackTrace) {
      debugPrint('[$_tag] ❌ Error in handleUpdatePhoto: $e');
      AppLogger.error(
        'Error updating profile photo: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      
      // Volta ao estado anterior
      if (_currentData != null) {
        _setState(EditProfileStateLoaded(
          formData: _currentData!.toFirestore(),
          hasUnsavedChanges: _hasChanges(),
        ));
      }
      
      _emitCommand(UpdatePhotoErrorCommand('Erro ao atualizar foto'));
      
      return PhotoUploadResultFailure(
        messageKey: 'update_photo_error',
        errorDetails: e.toString(),
      );
    }
  }
  
  /// Limpa o último command (após View executar)
  void clearCommand() {
    _lastCommand = null;
  }
  
  // ==================== PRIVATE METHODS ====================
  
  void _setState(EditProfileState newState) {
    _state = newState;
    notifyListeners();
  }
  
  void _emitCommand(EditProfileCommand command) {
    _lastCommand = command;
    notifyListeners();
  }
  
  void _emitError(String message) {
    _setState(EditProfileStateError(message));
    _emitCommand(SaveProfileErrorCommand(message));
  }
  
  bool _hasChanges() {
    if (_originalData == null || _currentData == null) return false;
    
    // Compara campos relevantes
    final original = _originalData!.toFirestore();
    final current = _currentData!.toFirestore();
    
    return original.toString() != current.toString();
  }
  
  /// Atualiza o usuário atual no AppState buscando do Firestore
  Future<void> _refreshCurrentUser() async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) return;
      
      final userDoc = await _firestore
          .collection('Users')
          .doc(currentUserId)
          .get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final updatedUser = app_user.User.fromDocument(userDoc.data()!);
        AppState.currentUser.value = updatedUser;
        AppLogger.info('AppState.currentUser updated', tag: _tag);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error refreshing current user: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      // Não propaga o erro, apenas loga
    }
  }
}
