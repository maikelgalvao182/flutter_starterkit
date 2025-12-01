import 'package:flutter/material.dart';

/// Serviço para gerenciar unidades de distância (km/mi)
class DistanceUnitService extends ChangeNotifier {
  bool _useMiles = false;
  
  /// Se está usando milhas ao invés de quilômetros
  bool get useMiles => _useMiles;
  
  /// Alterna entre km e milhas
  Future<void> toggleUnit() async {
    _useMiles = !_useMiles;
    notifyListeners();
    
    // TODO: Salvar preferência no SharedPreferences
  }
  
  /// Converte distância baseada na unidade selecionada
  double convertDistance(double distanceInKm) {
    return _useMiles ? distanceInKm * 0.621371 : distanceInKm;
  }
  
  /// Retorna a unidade como string
  String get unitString => _useMiles ? 'mi' : 'km';
}