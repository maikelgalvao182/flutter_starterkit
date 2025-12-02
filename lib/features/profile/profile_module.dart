// Barrel file para facilitar imports do módulo Profile

// Domain
export 'domain/models/profile_form_data.dart';
export 'domain/models/edit_profile_state.dart';
export 'domain/repositories/profile_repository_interface.dart';

// Data
export 'data/repositories/profile_repository.dart';
export 'data/services/image_upload_service.dart';

// Presentation
export 'presentation/viewmodels/edit_profile_view_model.dart';
export 'presentation/screens/profile_screen_router.dart';
export 'presentation/widgets/edit_profile_app_bar.dart';
export 'presentation/widgets/profile_photo_widget.dart';

// DI
export 'di/profile_dependency_provider.dart';
