import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partiu/features/home/presentation/screens/location_picker/place_service.dart';
import 'package:partiu/plugins/locationpicker/entities/location_result.dart';
import 'package:partiu/plugins/locationpicker/entities/localization_item.dart';
import 'package:partiu/plugins/locationpicker/place_picker.dart';
import 'package:partiu/plugins/locationpicker/uuid.dart';

/// Controller que gerencia todo o estado do LocationPicker
class LocationPickerController extends ChangeNotifier {
  LocationPickerController({
    required this.placeService,
    required this.localizationItem,
    LatLng? initialLocation,
  }) : _currentLocation = initialLocation;

  final PlaceService placeService;
  final LocalizationItem localizationItem;

  // Estado do mapa
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};

  // Estado dos lugares
  LocationResult? _locationResult;
  List<NearbyPlace> _nearbyPlaces = [];

  // Estado do autocomplete
  List<RichSuggestion> _suggestions = [];
  bool _hasSearchTerm = false;
  String _previousSearchTerm = '';
  String _sessionToken = Uuid().generateV4();

  // Getters
  LatLng? get currentLocation => _currentLocation;
  LatLng? get selectedLocation => _selectedLocation;
  Set<Marker> get markers => _markers;
  LocationResult? get locationResult => _locationResult;
  List<NearbyPlace> get nearbyPlaces => _nearbyPlaces;
  List<RichSuggestion> get suggestions => _suggestions;
  bool get hasSearchTerm => _hasSearchTerm;

  /// Atualiza localização atual
  void setCurrentLocation(LatLng location) {
    _currentLocation = location;
    notifyListeners();
  }

  /// Atualiza marcador no mapa
  void setMarker(LatLng location) {
    debugPrint('🟢 [Controller] setMarker chamado para: $location');
    _selectedLocation = location;
    _markers = {
      Marker(
        markerId: const MarkerId('selected-location'),
        position: location,
      ),
    };
    debugPrint('✅ [Controller] Markers definidos, chamando notifyListeners...');
    notifyListeners();
    debugPrint('✅ [Controller] notifyListeners concluído');
  }

  /// Move para uma localização e atualiza dados
  Future<void> moveToLocation(LatLng location, {bool loadNearby = false}) async {
    debugPrint('🟢 [Controller] moveToLocation iniciado: $location');
    setMarker(location);
    debugPrint('✅ [Controller] Marker definido');

    // Sempre carregar reverse geocoding para mostrar o endereço
    try {
      debugPrint('🟢 [Controller] Iniciando reverse geocoding...');
      await _loadReverseGeocode(location).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏰ [Controller] Timeout no reverse geocoding');
        },
      );
      debugPrint('✅ [Controller] Reverse geocoding concluído');
    } catch (e) {
      debugPrint('❌ [Controller] Erro no reverse geocoding: $e');
    }
    
    // Só carregar lugares próximos se solicitado
    if (loadNearby) {
      try {
        debugPrint('🟢 [Controller] Iniciando busca de lugares próximos...');
        await _loadNearbyPlaces(location).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⏰ [Controller] Timeout na busca de lugares próximos');
          },
        );
        debugPrint('✅ [Controller] Busca de lugares próximos concluída');
      } catch (e) {
        debugPrint('❌ [Controller] Erro ao buscar lugares próximos: $e');
      }
    }
    
    debugPrint('🏁 [Controller] moveToLocation concluído');
  }

  /// Carrega reverse geocoding
  Future<void> _loadReverseGeocode(LatLng location) async {
    debugPrint('🟢 [Controller] _loadReverseGeocode chamado');
    final result = await placeService.reverseGeocode(
      location: location,
      languageCode: localizationItem.languageCode,
    );
    debugPrint('✅ [Controller] Reverse geocoding retornou: ${result != null}');

    if (result != null) {
      _locationResult = result;
      debugPrint('✅ [Controller] LocationResult definido: ${result.formattedAddress}');
      notifyListeners();
      debugPrint('✅ [Controller] Listeners notificados');
    } else {
      debugPrint('⚠️ [Controller] Reverse geocoding retornou null');
    }
  }

  /// Carrega lugares próximos
  Future<void> _loadNearbyPlaces(LatLng location) async {
    debugPrint('🟢 [Controller] _loadNearbyPlaces chamado');
    final places = await placeService.getNearbyPlaces(
      location: location,
      languageCode: localizationItem.languageCode,
    );
    debugPrint('✅ [Controller] Encontrados ${places.length} lugares próximos');

    _nearbyPlaces = places;
    _hasSearchTerm = false;
    notifyListeners();
    debugPrint('✅ [Controller] Listeners notificados');
  }

  /// Busca autocomplete
  Future<void> searchPlace(String query) async {
    if (query == _previousSearchTerm) {
      return;
    }

    _previousSearchTerm = query;
    _hasSearchTerm = query.isNotEmpty;

    if (query.isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    final results = await placeService.autocomplete(
      query: query,
      sessionToken: _sessionToken,
      localization: localizationItem,
      bias: _locationResult?.latLng,
    );

    _suggestions = results;
    notifyListeners();
  }

  /// Seleciona um lugar do autocomplete
  Future<LatLng?> selectPlaceFromSuggestion(String placeId) async {
    final location = await placeService.getPlaceLatLng(
      placeId: placeId,
      languageCode: localizationItem.languageCode,
    );

    if (location != null) {
      // Quando seleciona da busca, carrega os nearby places
      await moveToLocation(location, loadNearby: true);
    }

    return location;
  }

  /// Limpa termo de busca
  void clearSearch() {
    _hasSearchTerm = false;
    _suggestions = [];
    _previousSearchTerm = '';
    notifyListeners();
  }

  /// Reseta session token
  void resetSession() {
    _sessionToken = Uuid().generateV4();
  }

  /// Obtém nome da localização formatado
  String getLocationName() {
    if (_locationResult == null) {
      return localizationItem.unnamedLocation;
    }

    // Verificar se algum nearby place tem um nome melhor
    for (final np in _nearbyPlaces) {
      if (np.latLng == _locationResult?.latLng &&
          np.name != _locationResult?.locality) {
        _locationResult?.name = np.name;
        return '${np.name}, ${_locationResult?.locality}';
      }
    }

    return '${_locationResult?.name}, ${_locationResult?.locality}';
  }

  @override
  void dispose() {
    placeService.dispose();
    super.dispose();
  }
}
