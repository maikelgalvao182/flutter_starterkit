import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partiu/features/home/presentation/screens/location_picker/place_service.dart';
import 'package:partiu/plugins/locationpicker/entities/location_result.dart';
import 'package:partiu/plugins/locationpicker/entities/localization_item.dart';
import 'package:partiu/plugins/locationpicker/place_picker.dart';
import 'package:partiu/plugins/locationpicker/uuid.dart';
import 'dart:ui' show PlatformDispatcher;

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

  // Estado do lugar selecionado
  LocationResult? _locationResult;
  List<String> _selectedPlacePhotos = [];
  String? _selectedPlaceId;

  // Controla se deve ignorar updates automáticos do mapa
  bool _lockOnSelectedPlace = false;

  // Controla se usuário confirmou a seleção clicando no dropdown
  bool _isLocationConfirmed = false;

  // Nearby Places
  List<NearbyPlace> _nearbyPlaces = [];

  // Autocomplete
  List<RichSuggestion> _suggestions = [];
  bool _hasSearchTerm = false;
  String _previousSearchTerm = '';
  String _sessionToken = Uuid().generateV4();

  // Getters
  LatLng? get currentLocation => _currentLocation;
  LatLng? get selectedLocation => _selectedLocation;
  Set<Marker> get markers => _markers;
  LocationResult? get locationResult => _locationResult;
  List<String> get selectedPlacePhotos => _selectedPlacePhotos;
  List<NearbyPlace> get nearbyPlaces => _nearbyPlaces;
  bool get hasSearchTerm => _hasSearchTerm;
  List<RichSuggestion> get suggestions => _suggestions;
  bool get isLocked => _lockOnSelectedPlace;
  bool get isLocationConfirmed => _isLocationConfirmed;

  // -------------------------------------------------------------
  //  ATUALIZAÇÕES DO MAPA
  // -------------------------------------------------------------

  void setMarker(LatLng location) {
    _selectedLocation = location;
    _markers = {
      Marker(
        markerId: const MarkerId('selected-location'),
        position: location,
      ),
    };
  }

  Future<void> moveToLocation(LatLng location,
      {String? placeId, bool loadNearby = false}) async {
    // Evitar processamento se a localização não mudou significativamente
    if (_selectedLocation != null && _isSameCoord(_selectedLocation!, location) && placeId == null) {
      return;
    }

    setMarker(location);

    final isExplicitSelection = placeId != null;

    if (isExplicitSelection) {
      _selectedPlaceId = placeId;
      _lockOnSelectedPlace = true; // trava qualquer movimento automático
      await _loadPlacePhotos(placeId);
    }

    // reverse geocode NUNCA altera as fotos
    await _loadReverseGeocode(location);

    if (loadNearby) await _loadNearbyPlaces(location);
    
    // Notificar apenas uma vez após todas as operações
    notifyListeners();
  }

  // -------------------------------------------------------------
  //  BUSCAS
  // -------------------------------------------------------------

  Future<void> searchPlace(String query) async {
    if (query == _previousSearchTerm) return;

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
      countryCode: _locationResult?.country?.shortName ?? PlatformDispatcher.instance.locale.countryCode,
    );

    _suggestions = results;
    notifyListeners();
  }

  Future<LatLng?> selectPlaceFromSuggestion(String placeId) async {
    _selectedPlaceId = placeId;
    _lockOnSelectedPlace = true; // trava o mapa
    _isLocationConfirmed = true; // confirma a seleção

    // ✅ Buscar detalhes completos do lugar (name + formatted_address)
    final locationResult = await placeService.getPlaceDetails(
      placeId: placeId,
      languageCode: localizationItem.languageCode,
    );

    if (locationResult != null && locationResult.latLng != null) {
      final location = locationResult.latLng!;

      // Salvar resultado completo sem fazer reverse geocode
      _locationResult = locationResult;
      setMarker(location);

      // Carregar fotos e nearby
      await _loadPlacePhotos(placeId);
      await _loadNearbyPlaces(location);

      notifyListeners();
      return location;
    }

    return null;
  }

  // -------------------------------------------------------------
  //  LOADERS
  // -------------------------------------------------------------

  Future<void> _loadPlacePhotos(String placeId) async {
    try {
      final photos = await placeService.getPlacePhotos(
        placeId: placeId,
        languageCode: localizationItem.languageCode,
      );

      _selectedPlacePhotos = photos;
      notifyListeners();
    } catch (_) {
      _selectedPlacePhotos = [];
    }
  }

  Future<void> _loadReverseGeocode(LatLng location) async {
    final result = await placeService.reverseGeocode(
      location: location,
      languageCode: localizationItem.languageCode,
    );

    if (result != null) {
      _locationResult = result;
    }
  }

  Future<void> _loadNearbyPlaces(LatLng location) async {
    final places = await placeService.getNearbyPlaces(
      location: location,
      languageCode: localizationItem.languageCode,
    );

    _nearbyPlaces = places;
  }

  // -------------------------------------------------------------
  //  UTIL
  // -------------------------------------------------------------

  void clearSearch() {
    _hasSearchTerm = false;
    _suggestions = [];
    _previousSearchTerm = '';
    notifyListeners();
  }

  void clearPhotos() {
    _selectedPlacePhotos = [];
    _selectedPlaceId = null;
    notifyListeners();
  }

  /// Atualiza o locationResult diretamente (usado ao restaurar estado salvo)
  void updateLocationResult(LocationResult location) {
    _locationResult = location;
    if (location.latLng != null) {
      setMarker(location.latLng!);
    }
    if (location.placeId != null) {
      _selectedPlaceId = location.placeId;
      _isLocationConfirmed = true;
    }
    notifyListeners();
  }

  void unlockLocation() {
    _lockOnSelectedPlace = false;
    _isLocationConfirmed = false; // remove confirmação ao mover mapa manualmente
    notifyListeners();
  }

  String getLocationName() {
    if (_locationResult == null) {
      return localizationItem.unnamedLocation;
    }

    final result = _locationResult!;

    if (result.name != null && result.name!.isNotEmpty) {
      return result.name!;
    }

    if (result.locality != null && result.locality!.isNotEmpty) {
      return result.locality!;
    }

    return result.formattedAddress ?? localizationItem.unnamedLocation;
  }

  bool _isSameCoord(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.00001 &&
        (a.longitude - b.longitude).abs() < 0.00001;
  }

  @override
  void dispose() {
    placeService.dispose();
    super.dispose();
  }
}
