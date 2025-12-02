import 'package:partiu/core/models/user.dart';

/// Interface para estratégias de cálculo de completude de perfil
abstract class IProfileCompletenessCalculator {
  /// Calcula a pontuação de completude (0-100)
  int calculate(User user);
  
  /// Retorna detalhes granulares do cálculo (para debug/logs)
  Map<String, dynamic> getDetails(User user);
}
