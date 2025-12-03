import 'dart:async';

import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/features/location/domain/repositories/location_repository_interface.dart';
import 'package:partiu/core/services/state_abbreviation_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Estados do rastreamento de localização
enum LocationTrackingState {
  idle,
  loading,
  ready,
  error,
}

/// Estados do salvamento de localização
enum LocationSaveState {
  idle,
  loading,
  success,
  error,
}

class UpdateLocationViewModel extends ChangeNotifier {
  
  UpdateLocationViewModel({
    required LocationRepositoryInterface locationRepository,
  }) : _locationRepository = locationRepository;
  final LocationRepositoryInterface _locationRepository;
  
  // Estados gerais
  bool _isLoading = false;
  String? _errorMessage;
  
  // Estados de rastreamento
  LocationTrackingState _trackingState = LocationTrackingState.idle;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  StreamSubscription<Position>? _positionSubscription;
  
  // Estados de salvamento
  LocationSaveState _saveState = LocationSaveState.idle;
  String? _savedLocation;
  String? _saveError;
  
  // Default location (São Paulo, Brazil)
  static const LatLng defaultLocation = LatLng(-23.5505, -46.6333);
  
  // Getters gerais
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Getters de rastreamento
  LocationTrackingState get trackingState => _trackingState;
  LatLng? get currentPosition => _currentPosition;
  Set<Marker> get markers => _markers;
  bool get isLocationReady => _trackingState == LocationTrackingState.ready;
  
  // Getters de salvamento
  LocationSaveState get saveState => _saveState;
  String? get savedLocation => _savedLocation;
  String? get saveError => _saveError;
  
  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
  
  /// Verifica o status da permissão sem solicitar
  Future<LocationPermission> checkPermissionStatus() async {
    return await Geolocator.checkPermission();
  }
  
  /// Solicita permissão de localização explicitamente
  Future<LocationPermission> requestLocationPermission() async {
    // Verifica se o serviço está habilitado primeiro
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warning('Location service not enabled', tag: 'UpdateLocationVM');
      return LocationPermission.denied;
    }
    
    // Verifica permissão atual
    var permission = await Geolocator.checkPermission();
    
    // Se já foi negada permanentemente, não pode solicitar novamente
    if (permission == LocationPermission.deniedForever) {
      AppLogger.warning('Location permission denied forever', tag: 'UpdateLocationVM');
      return LocationPermission.deniedForever;
    }
    
    // Solicita permissão
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      AppLogger.info('Permission request result: $permission', tag: 'UpdateLocationVM');
    }
    
    return permission;
  }
  
  /// Inicia o rastreamento de localização em tempo real
  /// IMPORTANTE: A permissão deve ser solicitada ANTES de chamar este método
  Future<void> startLocationTracking(String locationNotAvailable) async {
    _trackingState = LocationTrackingState.loading;
    notifyListeners();
    
    try {
      // Verifica se o serviço de localização está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location service not enabled', tag: 'UpdateLocationVM');
        _setDefaultLocation(locationNotAvailable);
        return;
      }

      // Apenas verifica a permissão (não solicita mais aqui)
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permission not granted: $permission', tag: 'UpdateLocationVM');
        _setDefaultLocation(locationNotAvailable);
        return;
      }

      // Obtém posição atual
      final position = await Geolocator.getCurrentPosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);
      
      _currentPosition = currentLatLng;
      _trackingState = LocationTrackingState.ready;
      _updateMarker(currentLatLng, locationNotAvailable);
      notifyListeners();

      // Inicia stream de posições em tempo real
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Atualiza a cada 10 metros
        ),
      ).listen((Position position) {
        final newPosition = LatLng(position.latitude, position.longitude);
        _currentPosition = newPosition;
        _updateMarker(newPosition, locationNotAvailable);
        notifyListeners();
      });

      AppLogger.success('Location tracking started', tag: 'UpdateLocationVM');

    } catch (e) {
      AppLogger.error('Failed to start location tracking: $e', tag: 'UpdateLocationVM');
      _setDefaultLocation(locationNotAvailable);
    }
  }
  
  /// Define localização padrão em caso de erro
  void _setDefaultLocation(String locationNotAvailable) {
    _currentPosition = defaultLocation;
    _trackingState = LocationTrackingState.error;
    _errorMessage = locationNotAvailable;
    _updateMarker(defaultLocation, locationNotAvailable);
    notifyListeners();
  }
  
  /// Atualiza o marcador no mapa
  void _updateMarker(LatLng position, String yourCurrentLocation) {
    _markers = {
      Marker(
        markerId: const MarkerId('current_location'),
        position: position,
        infoWindow: InfoWindow(
          title: yourCurrentLocation,
          snippet: 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };
  }
  
  /// Atualiza posição manualmente (quando usuário toca no mapa)
  void updatePositionManually(LatLng position, String yourCurrentLocation) {
    _currentPosition = position;
    _trackingState = LocationTrackingState.ready;
    _updateMarker(position, yourCurrentLocation);
    notifyListeners();
  }
  
  /// Aguarda até que a localização esteja pronta
  Future<bool> waitForLocationReady({int maxAttempts = 50}) async {
    if (isLocationReady && _currentPosition != null) {
      return true;
    }
    
    AppLogger.info('⏳ Waiting for GPS to be ready...', tag: 'UpdateLocationVM');
    
    var attempts = 0;
    while (!isLocationReady && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    final ready = isLocationReady && _currentPosition != null;
    if (!ready) {
      AppLogger.warning('GPS timeout - location not available', tag: 'UpdateLocationVM');
    }
    
    return ready;
  }
  
  /// Salva a localização atual
  Future<void> saveCurrentLocation(String userId) async {
    if (_currentPosition == null) {
      _saveState = LocationSaveState.error;
      _saveError = 'No location available';
      notifyListeners();
      return;
    }
    
    await saveLocationDirectly(
      userId: userId,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
    );
  }
  
  Future<void> saveLocationDirectly({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    _saveState = LocationSaveState.loading;
    _isLoading = true;
    _saveError = null;
    _savedLocation = null;
    notifyListeners();
    
    try {
      AppLogger.info('Saving location - lat: $latitude, lng: $longitude', tag: 'UpdateLocationVM');
      
      // Get user readable address
      final place = await _locationRepository.getUserAddress(
        latitude,
        longitude,
      );
      
      // Get locality and state
      String? locality;
      String? state;
      // Check locality
      if (place.locality == null || place.locality!.isEmpty) {
        locality = place.administrativeArea;
      } else {
        locality = place.locality;
      }
      // Get state from administrativeArea
      state = place.administrativeArea ?? '';
      
      // Abrevia o estado antes de salvar
      final stateAbbr = StateAbbreviationService.getAbbreviation(state);
      
      // ✅ GARANTIR conversão para String explícita
      final countryStr = place.country?.toString() ?? '';
      final localityStr = locality?.toString() ?? '';
      final stateStr = stateAbbr.toString();
      
      AppLogger.info('Location data: country=$countryStr, locality=$localityStr, state=$stateStr', tag: 'UpdateLocationVM');
      
      // ⚠️ VALIDAÇÃO: Backend requer todos os campos não vazios
      if (countryStr.isEmpty) {
        throw Exception('País está vazio. Não é possível salvar localização sem país.');
      }
      if (localityStr.isEmpty) {
        throw Exception('Cidade está vazia. Não é possível salvar localização sem cidade.');
      }
      if (stateStr.isEmpty) {
        throw Exception('Estado está vazio. Não é possível salvar localização sem estado.');
      }
      
      // Update User location
      await _locationRepository.updateUserLocation(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        country: countryStr,
        locality: localityStr,
        state: stateStr,
      );
      
      _saveState = LocationSaveState.success;
      _isLoading = false;
      _savedLocation = '$countryStr, $localityStr, $stateAbbr';
      
      AppLogger.success('Location saved successfully', tag: 'UpdateLocationVM');
      notifyListeners();
      
    } on TimeoutException {
      _saveState = LocationSaveState.error;
      _isLoading = false;
      _saveError = 'Location request timed out';
      
      AppLogger.error('Timeout saving location', tag: 'UpdateLocationVM');
      notifyListeners();
      
    } catch (e) {
      _saveState = LocationSaveState.error;
      _isLoading = false;
      _saveError = 'Failed to save location: $e';
      
      AppLogger.error('Error saving location: $e', tag: 'UpdateLocationVM');
      notifyListeners();
    }
  }
  
  /// Reseta o estado de salvamento
  void resetSaveState() {
    _saveState = LocationSaveState.idle;
    _saveError = null;
    _savedLocation = null;
    notifyListeners();
  }
}
