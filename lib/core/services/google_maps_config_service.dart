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
  String? _placesWebServiceKey;
  bool _isInitialized = false;

  String? _extractApiKeyFromData(Map<String, dynamic>? data) {
    if (data == null) return null;

    final candidates = <String?>[
      (data['Api_key'] as String?)?.trim(),
      (data['api_key'] as String?)?.trim(),
      (data['API_KEY'] as String?)?.trim(),
      (data['key'] as String?)?.trim(),
    ];

    for (final value in candidates) {
      if (value != null && value.isNotEmpty) return value;
    }

    return null;
  }

  Future<String?> _tryLoadKeyFromDoc(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection(C_APP_INFO).doc(docId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      return _extractApiKeyFromData(data);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        print('⚠️ [GoogleMapsConfig] Sem permissão para ler AppInfo/$docId (ok).');
        return null;
      }
      rethrow;
    }
  }

  /// Inicializa e carrega as chaves do Firebase
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔑 [GoogleMapsConfig] Carregando API Keys do Firebase...');
      
      // Buscar chave Android do documento GoogleAndroidMaps
      try {
        final androidDoc = await FirebaseFirestore.instance
            .collection(C_APP_INFO)
            .doc('GoogleAndroidMaps')
            .get();

        print('🔑 [GoogleMapsConfig] AndroidDoc exists: ${androidDoc.exists}');
        if (androidDoc.exists) {
          final data = androidDoc.data();
          print('🔑 [GoogleMapsConfig] AndroidDoc data keys: ${data?.keys}');
          print('🔑 [GoogleMapsConfig] AndroidDoc full data: $data');
          _androidMapsKey = _extractApiKeyFromData(data);
        } else {
          print('❌ [GoogleMapsConfig] AndroidDoc NOT FOUND! Path: AppInfo/GoogleAndroidMaps');
        }
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          print('⚠️ [GoogleMapsConfig] Sem permissão para ler AppInfo/GoogleAndroidMaps (antes do login). Vai usar fallback nativo.');
        } else {
          rethrow;
        }
      }

      // Fallback: ler do AndroidManifest via MethodChannel
      if (Platform.isAndroid && (_androidMapsKey == null || _androidMapsKey!.isEmpty)) {
        try {
          final key = await _androidChannel.invokeMethod<String>('getManifestApiKey');
          _androidMapsKey = (key != null && key.trim().isNotEmpty) ? key.trim() : null;
        } catch (e) {
          print('⚠️ [GoogleMapsConfig] Falha ao obter API key do AndroidManifest via channel: $e');
        }
      }

      final androidPreview = _androidMapsKey != null && _androidMapsKey!.length > 10
          ? _androidMapsKey!.substring(0, 10)
          : _androidMapsKey;
      print('🔑 [GoogleMapsConfig] Android key loaded: ${_androidMapsKey != null ? "✅ ($androidPreview...)" : "❌ null"}');

      // Buscar chave iOS do documento GoogleMapsApiKey
      try {
        final iosDoc = await FirebaseFirestore.instance
            .collection(C_APP_INFO)
            .doc('GoogleMapsApiKey')
            .get();

        print('🔑 [GoogleMapsConfig] iOSDoc exists: ${iosDoc.exists}');
        if (iosDoc.exists) {
          final data = iosDoc.data();
          print('🔑 [GoogleMapsConfig] iOSDoc data keys: ${data?.keys}');
          print('🔑 [GoogleMapsConfig] iOSDoc full data: $data');
          _iosMapsKey = _extractApiKeyFromData(data);
        } else {
          print('❌ [GoogleMapsConfig] iOSDoc NOT FOUND! Path: AppInfo/GoogleMapsApiKey');
        }
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          print('⚠️ [GoogleMapsConfig] Sem permissão para ler AppInfo/GoogleMapsApiKey (antes do login).');
        } else {
          rethrow;
        }
      }

      final iosPreview = _iosMapsKey != null && _iosMapsKey!.length > 10
          ? _iosMapsKey!.substring(0, 10)
          : _iosMapsKey;
      print('🔑 [GoogleMapsConfig] iOS key loaded: ${_iosMapsKey != null ? "✅ ($iosPreview...)" : "⚠️ null"}');

      _isInitialized = true;

        // Buscar chave do Places Web Service (mesma para iOS/Android)
        // Observação: para chamadas HTTP do Places API, uma chave restrita por app (Android/iOS) costuma falhar.
        // Tentamos nomes comuns de documento para não quebrar installs existentes.
        _placesWebServiceKey ??= await _tryLoadKeyFromDoc('GooglePlacesApiKey');
        _placesWebServiceKey ??= await _tryLoadKeyFromDoc('GooglePlacesWebService');
        _placesWebServiceKey ??= await _tryLoadKeyFromDoc('GooglePlacesWebServiceKey');
        _placesWebServiceKey ??= await _tryLoadKeyFromDoc('GooglePlaces');

        final placesPreview = _placesWebServiceKey != null && _placesWebServiceKey!.length > 10
          ? _placesWebServiceKey!.substring(0, 10)
          : _placesWebServiceKey;
        print('🔑 [GoogleMapsConfig] Places WebService key loaded: ${_placesWebServiceKey != null ? "✅ ($placesPreview...)" : "⚠️ null (vai usar fallback)"}');

      if (_androidMapsKey == null && _iosMapsKey == null) {
        // Não falhar aqui: Android pode estar configurado via AndroidManifest e iOS via AppDelegate.
        print('⚠️ [GoogleMapsConfig] Nenhuma chave carregada do Firebase (ok se chaves estiverem no nativo).');
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
  /// Preferencialmente usa uma chave dedicada ao Places Web Service (sem restrição por app).
  /// Se não existir no Firebase, faz fallback para a chave do Maps da plataforma (pode falhar no Android).
  Future<String> getGooglePlacesApiKey() async {
    await initialize();

    if (_placesWebServiceKey != null && _placesWebServiceKey!.isNotEmpty) {
      return _placesWebServiceKey!;
    }

    print('⚠️ [GoogleMapsConfig] Places WebService key ausente. Fazendo fallback para Maps key (pode causar REQUEST_DENIED no Places HTTP).');
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