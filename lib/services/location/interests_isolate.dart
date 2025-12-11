import 'dart:isolate';

/// Isolate worker para cálculo de interesses em comum em background
/// 
/// Evita jank na UI ao processar grandes volumes de usuários
/// Similar ao DistanceIsolate - mantém padrão do projeto

/// Entrada para o isolate
class InterestsCalculationRequest {
  final List<UserInterestsData> users;
  final List<String> myInterests;

  const InterestsCalculationRequest({
    required this.users,
    required this.myInterests,
  });
}

/// Dados simplificados de usuário para isolate
class UserInterestsData {
  final String userId;
  final List<String> interests;

  const UserInterestsData({
    required this.userId,
    required this.interests,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'interests': interests,
      };

  factory UserInterestsData.fromJson(Map<String, dynamic> json) {
    return UserInterestsData(
      userId: json['userId'] as String,
      interests: List<String>.from(json['interests'] as List),
    );
  }
}

/// Resultado do cálculo de interesses
class UserInterestsResult {
  final String userId;
  final List<String> commonInterests;
  final double percentage; // 0.0 a 1.0

  const UserInterestsResult({
    required this.userId,
    required this.commonInterests,
    required this.percentage,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'commonInterests': commonInterests,
        'percentage': percentage,
      };

  factory UserInterestsResult.fromJson(Map<String, dynamic> json) {
    return UserInterestsResult(
      userId: json['userId'] as String,
      commonInterests: List<String>.from(json['commonInterests'] as List),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

/// Função principal do isolate - DEVE ser top-level
/// 
/// Calcula interesses em comum para múltiplos usuários
/// Retorna lista com resultados para cada usuário
List<UserInterestsResult> calculateCommonInterests(
  InterestsCalculationRequest request,
) {
  final results = <UserInterestsResult>[];
  final myInterestsSet = request.myInterests.toSet();

  for (final user in request.users) {
    final userInterestsSet = user.interests.toSet();
    final common = myInterestsSet.intersection(userInterestsSet).toList();
    
    // Calcular porcentagem (baseado nos interesses do usuário)
    final percentage = user.interests.isEmpty 
        ? 0.0 
        : common.length / user.interests.length;

    results.add(
      UserInterestsResult(
        userId: user.userId,
        commonInterests: common,
        percentage: percentage,
      ),
    );
  }

  return results;
}

/// Helper para executar o isolate usando SendPort/ReceivePort
/// 
/// Uso:
/// ```dart
/// final results = await InterestsIsolate.calculate(
///   users: usersList,
///   myInterests: myInterestsList,
/// );
/// ```
class InterestsIsolate {
  /// Executa cálculo de interesses em isolate separado
  static Future<List<UserInterestsResult>> calculate({
    required List<UserInterestsData> users,
    required List<String> myInterests,
  }) async {
    final request = InterestsCalculationRequest(
      users: users,
      myInterests: myInterests,
    );

    // Criar ReceivePort para receber resultado
    final receivePort = ReceivePort();
    
    // Criar isolate
    await Isolate.spawn(
      _isolateEntryPoint,
      _IsolateMessage(
        sendPort: receivePort.sendPort,
        request: request,
      ),
    );

    // Aguardar resultado
    final result = await receivePort.first as List<UserInterestsResult>;
    
    return result;
  }

  /// Entry point do isolate
  static void _isolateEntryPoint(_IsolateMessage message) {
    final results = calculateCommonInterests(message.request);
    message.sendPort.send(results);
  }
}

/// Mensagem para comunicação com isolate
class _IsolateMessage {
  final SendPort sendPort;
  final InterestsCalculationRequest request;

  const _IsolateMessage({
    required this.sendPort,
    required this.request,
  });
}
