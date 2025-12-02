import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:partiu/core/constants/constants.dart';

/// Serviço para fornecer as API Keys do Google Maps
/// As chaves são carregadas do Firebase Firestore (AppInfo collection)
class GoogleMapsConfigService {
  factory GoogleMapsConfigService() => _instance;
  GoogleMapsConfigService._internal();
  static final GoogleMapsConfigService _instance = GoogleMapsConfigService._internal();

  // Method channels para comunicação com código nativo
  static const MethodChannel _iosChannel = MethodChannel('com.example.partiu/google_maps_ios');
  static const MethodChannel _androidChannel = MethodChannel('com.example.partiu/google_maps');

  // Cache das chaves
  String? _androidMapsKey;
  String? _iosMapsKey;
  bool _isInitialized = false;

  /// Inicializa e carrega as chaves do Firebase
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔑 [GoogleMapsConfig] Carregando API Keys do Firebase...');
      
      // Buscar chave Android do documento GoogleAndroidMaps
      final androidDoc = await FirebaseFirestore.instance
          .collection(C_APP_INFO)
          .doc('GoogleAndroidMaps')
          .get();

      print('🔑 [GoogleMapsConfig] AndroidDoc exists: ${androidDoc.exists}');
      if (androidDoc.exists) {
        final data = androidDoc.data();
        print('🔑 [GoogleMapsConfig] AndroidDoc data keys: ${data?.keys}');
        _androidMapsKey = (data?['Api_key'] as String?)?.trim();
        final androidPreview = _androidMapsKey != null && _androidMapsKey!.length > 10 ? _androidMapsKey!.substring(0, 10) : _androidMapsKey;
        print('🔑 [GoogleMapsConfig] Android key loaded: ${_androidMapsKey != null ? "✅ ($androidPreview...)" : "❌ null"}');
        if (_androidMapsKey != null) {
          print('🔑 [GoogleMapsConfig] Android key length: ${_androidMapsKey!.length}');
        }
      } else {
        print('❌ [GoogleMapsConfig] AndroidDoc NOT FOUND! Path: AppInfo/GoogleAndroidMaps');
      }

      // Buscar chave iOS do documento GoogleMapsApiKey
      final iosDoc = await FirebaseFirestore.instance
          .collection(C_APP_INFO)
          .doc('GoogleMapsApiKey')
          .get();

      print('🔑 [GoogleMapsConfig] iOSDoc exists: ${iosDoc.exists}');
      if (iosDoc.exists) {
        final data = iosDoc.data();
        print('🔑 [GoogleMapsConfig] iOSDoc data keys: ${data?.keys}');
        _iosMapsKey = (data?['Api_key'] as String?)?.trim();
        final iosPreview = _iosMapsKey != null && _iosMapsKey!.length > 10 ? _iosMapsKey!.substring(0, 10) : _iosMapsKey;
        print('🔑 [GoogleMapsConfig] iOS key loaded: ${_iosMapsKey != null ? "✅ ($iosPreview...)" : "❌ null"}');
        if (_iosMapsKey != null) {
          print('🔑 [GoogleMapsConfig] iOS key length: ${_iosMapsKey!.length}');
        }
      } else {
        print('❌ [GoogleMapsConfig] iOSDoc NOT FOUND! Path: AppInfo/GoogleMapsApiKey');
      }

      _isInitialized = true;

      if (_androidMapsKey == null && _iosMapsKey == null) {
        print('❌ [GoogleMapsConfig] Nenhuma chave encontrada no Firebase!');
        throw Exception('Google Maps API keys not found in Firebase AppInfo collection');
      }
      
      // Configurar as API keys nativas após carregar do Firebase
      await _configureNativeApiKeys();
      
      print('✅ [GoogleMapsConfig] Inicialização completa');
    } catch (e) {
      print('❌ [GoogleMapsConfig] Erro ao carregar: $e');
      throw Exception('Failed to load Google Maps API keys from Firebase: $e');
    }
  }

  /// Configura as API keys no código nativo através de method channels
  Future<void> _configureNativeApiKeys() async {
    try {
      if (Platform.isIOS && _iosMapsKey != null) {
        print('🔑 [GoogleMapsConfig] Configurando chave iOS no nativo...');
        final result = await _iosChannel.invokeMethod('setApiKey', {'apiKey': _iosMapsKey});
        print('✅ [GoogleMapsConfig] iOS nativo configurado: $result');
      } else if (Platform.isAndroid && _androidMapsKey != null) {
        print('🔑 [GoogleMapsConfig] Configurando chave Android no nativo...');
        final result = await _androidChannel.invokeMethod('setApiKey', {'apiKey': _androidMapsKey});
        print('✅ [GoogleMapsConfig] Android nativo configurado: $result');
      }
    } catch (e) {
      print('⚠️ [GoogleMapsConfig] Aviso: Falha ao configurar chaves nativas: $e');
      // Não falhar a inicialização se o method channel falhar
    }
  }

  /// Retorna a Google Maps API Key baseado na plataforma
  /// Android: GoogleAndroidMaps (do Firebase)
  /// iOS: GoogleMapsApiKey (do Firebase)
  Future<String> getGoogleMapsApiKey() async {
    await initialize();

    if (Platform.isAndroid) {
      if (_androidMapsKey == null || _androidMapsKey!.isEmpty) {
        throw Exception('Android Maps API Key not configured in Firebase');
      }
      return _androidMapsKey!;
    } else if (Platform.isIOS) {
      if (_iosMapsKey == null || _iosMapsKey!.isEmpty) {
        throw Exception('iOS Maps API Key not configured in Firebase');
      }
      return _iosMapsKey!;
    } else {
      throw Exception('Plataforma não suportada para Google Maps');
    }
  }

  /// Retorna a Google Places API Key (HTTP Web Service)
  /// Usa a chave apropriada para cada plataforma:
  /// - iOS: GoogleMapsApiKey (restrita por bundle ID)
  /// - Android: GoogleAndroidMaps (restrita por package name)
  Future<String> getGooglePlacesApiKey() async {
    // Reutiliza a mesma lógica de getGoogleMapsApiKey
    return getGoogleMapsApiKey();
  }

  /// Força recarregar as chaves do Firebase
  Future<void> reload() async {
    _isInitialized = false;
    _androidMapsKey = null;
    _iosMapsKey = null;
    await initialize();
  }
}