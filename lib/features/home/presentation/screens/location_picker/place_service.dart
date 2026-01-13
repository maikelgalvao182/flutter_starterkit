import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/plugins/locationpicker/entities/localization_item.dart';
import 'package:partiu/plugins/locationpicker/place_picker.dart';

/// Service para comunicação com Google Places API
class PlaceService {
  PlaceService({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _httpClient;

  /// Autocomplete de lugares
  Future<List<RichSuggestion>> autocomplete({
    required String query,
    required String sessionToken,
    required LocalizationItem localization,
    LatLng? bias,
    String? countryCode,
  }) async {
    try {
      final normalizedCountryCode = (countryCode ?? '').trim().toLowerCase();

      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        <String, String>{
          'key': apiKey,
          'language': localization.languageCode,
          'input': query,
          'sessiontoken': sessionToken,
          if (normalizedCountryCode.isNotEmpty)
            'components': 'country:$normalizedCountryCode',
          if (bias != null) ...{
            'location': '${bias.latitude},${bias.longitude}',
            // Bias suave para não “matar” resultados; também evita comportamento estranho sem radius.
            'radius': '50000',
          },
        },
      );

      final response = await _httpClient.get(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Autocomplete timeout'),
          );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          AppLogger.warning(
            'Places autocomplete HTTP ${response.statusCode}',
            tag: 'PLACES',
          );
        }
        throw Exception('Autocomplete failed: ${response.statusCode}');
      }

      final responseJson = json.decode(response.body) as Map<String, dynamic>;

      if (kDebugMode) {
        final status = responseJson['status'];
        if (status != null && status != 'OK' && status != 'ZERO_RESULTS') {
          AppLogger.warning(
            'Places autocomplete status=$status message=${responseJson['error_message'] ?? ''}',
            tag: 'PLACES',
          );
        }
      }

      if (responseJson['status'] != null &&
          responseJson['status'] != 'OK' &&
          responseJson['status'] != 'ZERO_RESULTS') {
        throw Exception('API error: ${responseJson['status']}');
      }

      if (responseJson['predictions'] == null) {
        return [];
      }

      final List<dynamic> predictions = responseJson['predictions'];

      if (predictions.isEmpty) {
        // Retornar lista vazia ao invés de item "no results found"
        return [];
      }

      return predictions.map((t) {
        final matchedSubstrings = (t['matched_substrings'] as List<dynamic>?) ?? const [];
        final firstMatch = matchedSubstrings.isNotEmpty ? matchedSubstrings.first as Map<String, dynamic>? : null;

        final aci = AutoCompleteItem()
          ..id = t['place_id'] as String?
          ..text = t['description'] as String?
          ..offset = (firstMatch?['offset'] as num?)?.toInt() ?? 0
          ..length = (firstMatch?['length'] as num?)?.toInt() ?? 0;
        return RichSuggestion(aci, () {});
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        AppLogger.warning(
          'Places autocomplete falhou: $e',
          tag: 'PLACES',
        );
      }
      return [];
    }
  }

  /// Busca detalhes completos de um lugar por ID
  /// Retorna name, formatted_address e coordenadas
  Future<LocationResult?> getPlaceDetails({
    required String placeId,
    required String languageCode,
  }) async {
    try {
      // ✅ SOLUÇÃO: Buscar campos essenciais (name, formatted_address, geometry)
      // Nunca usar plus_code, vicinity ou secondary_text
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'key=$apiKey&'
        'language=$languageCode&'
        'fields=name,formatted_address,geometry,address_components,place_id&'
        'placeid=$placeId',
      );

      final response = await _httpClient.get(url).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Place details timeout'),
          );

      if (response.statusCode != 200) {
        throw Exception('Place details failed: ${response.statusCode}');
      }

      final responseJson = json.decode(response.body) as Map<String, dynamic>;

      if (responseJson['status'] != 'OK') {
        throw Exception('API error: ${responseJson['status']}');
      }

      final result = responseJson['result'] as Map<String, dynamic>;
      final location = result['geometry']['location'];
      final latLng = LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      );

      // ✅ Extrair name e formatted_address (NUNCA plus_code)
      final name = result['name'] as String?;
      final formattedAddress = result['formatted_address'] as String?;

      // Extrair componentes do endereço
      String? locality;
      String? country;
      String? administrativeAreaLevel1;
      String? administrativeAreaLevel2;
      String? subLocalityLevel1;
      String? subLocalityLevel2;
      String? postalCode;

      final components = result['address_components'] as List<dynamic>?;
      if (components != null) {
        for (final component in components) {
          final types = component['types'] as List<dynamic>;
          final shortName = component['short_name'] as String?;

          if (types.contains('sublocality_level_1')) {
            subLocalityLevel1 = shortName;
          } else if (types.contains('sublocality_level_2')) {
            subLocalityLevel2 = shortName;
          } else if (types.contains('locality')) {
            locality = shortName;
          } else if (types.contains('administrative_area_level_2')) {
            administrativeAreaLevel2 = shortName;
          } else if (types.contains('administrative_area_level_1')) {
            administrativeAreaLevel1 = shortName;
          } else if (types.contains('country')) {
            country = shortName;
          } else if (types.contains('postal_code')) {
            postalCode = shortName;
          }
        }
      }

      // locality (cidade) com fallback para administrative_area_level_2
      // administrativeAreaLevel1 (estado) mantido separado
      final cityName = locality ?? administrativeAreaLevel2;
      final stateName = administrativeAreaLevel1;

      return LocationResult()
        ..name = name
        ..formattedAddress = formattedAddress
        ..latLng = latLng
        ..placeId = placeId
        ..locality = cityName
        ..postalCode = postalCode
        ..country = AddressComponent(name: country, shortName: country)
        ..administrativeAreaLevel1 = AddressComponent(
          name: stateName,
          shortName: stateName,
        )
        ..administrativeAreaLevel2 = AddressComponent(
          name: administrativeAreaLevel2,
          shortName: administrativeAreaLevel2,
        )
        ..city = AddressComponent(name: cityName, shortName: cityName)
        ..subLocalityLevel1 = AddressComponent(
          name: subLocalityLevel1,
          shortName: subLocalityLevel1,
        )
        ..subLocalityLevel2 = AddressComponent(
          name: subLocalityLevel2,
          shortName: subLocalityLevel2,
        );
    } catch (e) {
      return null;
    }
  }

  /// Busca fotos de um lugar específico por placeId
  Future<List<String>> getPlacePhotos({
    required String placeId,
    required String languageCode,
  }) async {
    // Importante: fotos do Google Places (Photos API) desativadas no app.
    // Retornar sempre vazio evita chamadas extras e qualquer download indireto.
    return [];
  }

  /// Busca lugares próximos a uma localização
  Future<List<NearbyPlace>> getNearbyPlaces({
    required LatLng location,
    required String languageCode,
    int radius = 150,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'key=$apiKey&'
        'location=${location.latitude},${location.longitude}&'
        'radius=$radius&'
        'language=$languageCode',
      );

      final response = await _httpClient.get(url).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Nearby places timeout'),
          );

      if (response.statusCode != 200) {
        throw Exception('Nearby places failed: ${response.statusCode}');
      }

      final responseJson = json.decode(response.body) as Map<String, dynamic>;

      if (responseJson['status'] != 'OK') {
        return [];
      }

      final results = responseJson['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return [];
      }

      return results.map((item) {
        return NearbyPlace()
          ..name = item['name'] as String?
          ..icon = item['icon'] as String?
          ..photoReference = null
          ..photoWidth = null
          ..photoHeight = null
          ..latLng = LatLng(
            (item['geometry']['location']['lat'] as num).toDouble(),
            (item['geometry']['location']['lng'] as num).toDouble(),
          );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Reverse geocoding - converte coordenadas em endereço
  Future<LocationResult?> reverseGeocode({
    required LatLng location,
    required String languageCode,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=${location.latitude},${location.longitude}&'
        'language=$languageCode&'
        'key=$apiKey',
      );

      final response = await _httpClient.get(url).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Reverse geocode timeout');
            },
          );

      if (response.statusCode != 200) {
        throw Exception('Reverse geocode failed: ${response.statusCode}');
      }

      final responseJson = json.decode(response.body) as Map<String, dynamic>;

      if (responseJson['status'] != 'OK') {
        throw Exception('API error: ${responseJson['status']}');
      }

      final result = responseJson['results'][0] as Map<String, dynamic>;

      // Extrair componentes do endereço
      var name = '';
      String? streetNumber;
      String? route;
      String? locality;
      String? postalCode;
      String? country;
      String? administrativeAreaLevel1;
      String? administrativeAreaLevel2;
      String? subLocalityLevel1;
      String? subLocalityLevel2;

      final components = result['address_components'] as List<dynamic>?;
      if (components != null && components.isNotEmpty) {
        for (final component in components) {
          final types = component['types'] as List<dynamic>;
          final shortName = component['short_name'] as String?;

          if (types.contains('street_number')) {
            streetNumber = shortName;
          } else if (types.contains('route')) {
            route = shortName;
          } else if (types.contains('sublocality_level_1')) {
            subLocalityLevel1 = shortName;
          } else if (types.contains('sublocality_level_2')) {
            subLocalityLevel2 = shortName;
          } else if (types.contains('locality')) {
            locality = shortName;
          } else if (types.contains('administrative_area_level_2')) {
            administrativeAreaLevel2 = shortName;
          } else if (types.contains('administrative_area_level_1')) {
            administrativeAreaLevel1 = shortName;
          } else if (types.contains('country')) {
            country = shortName;
          } else if (types.contains('postal_code')) {
            postalCode = shortName;
          }
        }
      }

      // Construir nome do local
      if (route != null && streetNumber != null) {
        name = route.trim().endsWith(streetNumber) ? route : '$route, $streetNumber';
      } else if (route != null) {
        name = route;
      } else if (streetNumber != null) {
        name = streetNumber;
      } else if (components != null && components.isNotEmpty) {
        name = components[0]['short_name'] as String? ?? '';
      }

      locality = locality ?? administrativeAreaLevel1;
      final city = locality;

      return LocationResult()
        ..name = name
        ..locality = locality
        ..latLng = location
        ..formattedAddress = result['formatted_address'] as String?
        ..placeId = result['place_id'] as String?
        ..postalCode = postalCode
        ..country = AddressComponent(name: country, shortName: country)
        ..administrativeAreaLevel1 = AddressComponent(
          name: administrativeAreaLevel1,
          shortName: administrativeAreaLevel1,
        )
        ..administrativeAreaLevel2 = AddressComponent(
          name: administrativeAreaLevel2,
          shortName: administrativeAreaLevel2,
        )
        ..city = AddressComponent(name: city, shortName: city)
        ..subLocalityLevel1 = AddressComponent(
          name: subLocalityLevel1,
          shortName: subLocalityLevel1,
        )
        ..subLocalityLevel2 = AddressComponent(
          name: subLocalityLevel2,
          shortName: subLocalityLevel2,
        );
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
