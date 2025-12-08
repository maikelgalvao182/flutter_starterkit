import 'package:flutter/foundation.dart';
import 'package:partiu/features/home/data/repositories/event_repository.dart';
import 'package:partiu/features/home/data/repositories/event_application_repository.dart';
import 'package:partiu/shared/repositories/user_repository.dart';

/// Controller para gerenciar dados do ListCard
class ListCardController extends ChangeNotifier {
  final EventRepository _eventRepo;
  final EventApplicationRepository _applicationRepo;
  final UserRepository _userRepo;
  final String eventId;

  // Event data
  String? _emoji;
  String? _activityText;
  String? _locationName;
  DateTime? _scheduleDate;
  String? _creatorId;

  // Creator data
  String? _creatorPhotoUrl;

  // Participants data (últimos 5)
  List<Map<String, dynamic>> _recentParticipants = [];
  int _totalParticipantsCount = 0;

  bool _loaded = false;
  bool _isLoading = false;
  String? _error;
  
  // ValueNotifiers para rebuild granular
  final ValueNotifier<bool> loadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> dataReadyNotifier = ValueNotifier(false);

  ListCardController({
    required this.eventId,
    EventRepository? eventRepo,
    EventApplicationRepository? applicationRepo,
    UserRepository? userRepo,
  })  : _eventRepo = eventRepo ?? EventRepository(),
        _applicationRepo = applicationRepo ?? EventApplicationRepository(),
        _userRepo = userRepo ?? UserRepository();

  // Getters
  String? get emoji => _emoji;
  String? get activityText => _activityText;
  String? get locationName => _locationName;
  DateTime? get scheduleDate => _scheduleDate;
  String? get creatorId => _creatorId;
  String? get creatorPhotoUrl => _creatorPhotoUrl;
  List<Map<String, dynamic>> get recentParticipants => _recentParticipants;
  int get totalParticipantsCount => _totalParticipantsCount;
  bool get isLoading => !_loaded && _error == null;
  String? get error => _error;
  bool get hasData => _loaded && _error == null;

  /// Carrega todos os dados necessários para o card
  Future<void> load() async {
    // Se já carregou ou está carregando, não faz nada
    if (_loaded || _isLoading) return;
    
    _isLoading = true;
    loadingNotifier.value = true;
    
    try {
      // Carregar dados do evento e participantes em paralelo
      final results = await Future.wait([
        _eventRepo.getEventBasicInfo(eventId),
        _applicationRepo.getRecentApplicationsWithUserData(eventId, limit: 5),
        _applicationRepo.getApprovedApplicationsCount(eventId),
      ]);

      // Parse event data
      final eventData = results[0] as Map<String, dynamic>?;
      if (eventData != null) {
        _emoji = eventData['emoji'] as String?;
        _activityText = eventData['activityText'] as String?;
        _locationName = eventData['locationName'] as String?;
        _scheduleDate = eventData['scheduleDate'] as DateTime?;
        _creatorId = eventData['createdBy'] as String?;
        
        // Buscar dados do criador (photoUrl)
        if (_creatorId != null) {
          final creatorData = await _userRepo.getUserBasicInfo(_creatorId!);
          _creatorPhotoUrl = creatorData?['photoUrl'] as String?;
        }
      }

      // Parse participants data
      _recentParticipants = results[1] as List<Map<String, dynamic>>;
      _totalParticipantsCount = results[2] as int;

      _loaded = true;
      _isLoading = false;
      loadingNotifier.value = false;
      dataReadyNotifier.value = true;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar dados: $e';
      _loaded = false;
      _isLoading = false;
      loadingNotifier.value = false;
      notifyListeners();
      debugPrint('❌ Erro no ListCardController: $e');
    }
  }

  /// Recarrega os dados
  Future<void> refresh() async {
    _loaded = false;
    _error = null;
    notifyListeners();
    await load();
  }
}
