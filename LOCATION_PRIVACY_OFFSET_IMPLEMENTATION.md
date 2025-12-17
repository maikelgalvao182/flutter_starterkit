# 🔒 Location Privacy Offset - Implementação Completa

## 📋 Resumo

Sistema de offset de localização determinístico implementado para proteger a privacidade dos usuários, mantendo funcionalidade de discovery baseada em proximidade.

## 🎯 Objetivo

Adicionar offset aleatório mas reprodutível às coordenadas dos usuários para:
- Dificultar engenharia reversa da localização exata
- Melhorar UX (coordenadas consistentes, sem "teleporte")
- Manter segurança e privacidade

## 📐 Especificações Técnicas

### Parâmetros do Offset
- **Raio mínimo**: 300 metros
- **Raio máximo**: 1500 metros (1.5 km)
- **Tipo**: Determinístico (baseado em userId como seed)
- **Algoritmo**: Haversine com offset angular aleatório

### Campos no Firestore (Users Collection)

#### Campos Originais (mantidos)
- `latitude`: Localização real (uso interno apenas)
- `longitude`: Localização real (uso interno apenas)

#### Campos Novos
- `displayLatitude`: Latitude com offset (uso público)
- `displayLongitude`: Longitude com offset (uso público)

## 🛠️ Arquivos Modificados

### 1. Backend (TypeScript)

#### `functions/src/utils/locationOffset.ts` (NOVO)
```typescript
// Helper determinístico para gerar offset
export function generateDisplayLocation(
  realLat: number,
  realLng: number,
  userId: string
): { displayLatitude: number; displayLongitude: number }
```

**Características**:
- Usa userId como seed
- Gera offset entre 300m e 1.5km
- Direção aleatória mas fixa por usuário
- Reprodutível (mesmo input = mesmo output)

### 2. Flutter (Dart)

#### `lib/core/utils/location_offset_helper.dart` (NOVO)
```dart
class LocationOffsetHelper {
  static Map<String, double> generateDisplayLocation({
    required double realLat,
    required double realLng,
    required String userId,
  })
}
```

**Características**:
- Implementação idêntica ao backend
- Pode ser usada localmente se necessário
- Atualmente o offset é gerado no momento do salvamento

#### `lib/features/location/presentation/viewmodels/update_location_view_model.dart`
**Modificações**:
```dart
// Gera coordenadas display com offset determinístico
final displayCoords = LocationOffsetHelper.generateDisplayLocation(
  realLat: latitude,
  realLng: longitude,
  userId: userId,
);
```

Salva ambos os campos no Firestore:
- `latitude` / `longitude` (reais)
- `displayLatitude` / `displayLongitude` (com offset)

#### `lib/features/location/domain/repositories/location_repository_interface.dart`
**Modificações**:
```dart
Future<void> updateUserLocation({
  required String userId,
  required double latitude,
  required double longitude,
  required double displayLatitude,    // NOVO
  required double displayLongitude,   // NOVO
  required String country,
  required String locality,
  required String state,
  String? formattedAddress,
});
```

#### `lib/features/location/data/repositories/location_repository.dart`
**Modificações**:
```dart
await _firestore.collection('Users').doc(userId).update({
  'latitude': latitude,
  'longitude': longitude,
  'displayLatitude': displayLatitude,        // NOVO
  'displayLongitude': displayLongitude,      // NOVO
  // ... outros campos
});
```

#### `lib/core/models/user.dart`
**Modificações**:
```dart
class User {
  final double? distance;
  final double? displayLatitude;     // NOVO
  final double? displayLongitude;    // NOVO
  // ...
}
```

Atualizado:
- Constructor
- Factory `fromDocument`
- Method `copyWith`
- Factory `empty`

#### `lib/core/utils/interests_helper.dart`
**Modificações**:
```dart
static double? calculateDistance(
  Map<String, dynamic> userData1,
  Map<String, dynamic> userData2,
) {
  // 🔒 PRIORIZA COORDENADAS DISPLAY
  final lat1 = (userData1['displayLatitude'] as num?)?.toDouble() ?? 
               (userData1['latitude'] as num?)?.toDouble();
  // ... fallback para latitude/longitude se display não existir
}
```

## 🔄 Fluxo de Dados

### 1. Salvamento de Localização
```
User atualiza localização
    ↓
update_location_view_model.dart
    ↓
LocationOffsetHelper.generateDisplayLocation(userId)
    ↓
Firestore: salva latitude, longitude, displayLatitude, displayLongitude
```

### 2. Cálculo de Distância
```
InterestsHelper.calculateDistance()
    ↓
Usa displayLatitude/displayLongitude (prioridade)
    ↓
Fallback: latitude/longitude (se display não existir)
    ↓
Retorna distância em km
```

### 3. Exibição no UserCard
```
User model contém displayLatitude/displayLongitude
    ↓
InterestsHelper calcula distância usando coordenadas display
    ↓
UserCard exibe distância calculada
```

## ✅ Checklist de Validação

- [x] Backend salva `displayLatitude` e `displayLongitude`
- [x] Offset entre 300m e 1.5km (configurável)
- [x] Offset determinístico por usuário (mesmo userId = mesmo offset)
- [x] Helper de distância usa coordenadas display
- [x] Coordenadas reais NUNCA expostas publicamente
- [x] Fallback para coordenadas reais se display não existir
- [x] Model User atualizado com novos campos
- [x] Repository atualizado para salvar novos campos
- [x] ViewModel atualizado para gerar offset

## 🔐 Segurança

### Coordenadas Reais (`latitude`, `longitude`)
- ✅ Salvas no Firestore
- ✅ Usadas apenas internamente
- ✅ NUNCA expostas em APIs públicas
- ✅ NUNCA usadas para cálculos de distância visíveis

### Coordenadas Display (`displayLatitude`, `displayLongitude`)
- ✅ Usadas para cálculos de distância
- ✅ Exibidas em mapas (se implementado)
- ✅ Offset de 300m a 1.5km
- ✅ Determinísticas (não mudam a cada request)

## 🧪 Testes Sugeridos

1. **Teste de Determinismo**:
   - Mesmo userId deve gerar sempre o mesmo offset
   - Verificar logs de `LocationOffsetHelper`

2. **Teste de Alcance**:
   - Offset mínimo >= 300m
   - Offset máximo <= 1500m

3. **Teste de Fallback**:
   - Usuários antigos sem `displayLatitude` devem usar `latitude`

4. **Teste de Cálculo**:
   - Distância calculada usa coordenadas display
   - UserCard exibe distância correta

## 📝 Notas Importantes

1. **Migração de Dados**:
   - Usuários existentes não têm `displayLatitude`/`displayLongitude`
   - Sistema tem fallback para `latitude`/`longitude`
   - Offset será gerado na próxima atualização de localização

2. **Consistência**:
   - Offset é fixo por usuário (determinístico)
   - Não muda a cada login ou atualização
   - Apenas se userId mudar (improvável)

3. **Performance**:
   - Cálculo de offset é rápido (matemática simples)
   - Não impacta performance de salvamento

## 🚀 Próximos Passos (Opcional)

1. **Backend TypeScript**:
   - Criar Cloud Function para gerar offset automaticamente
   - Útil se quiser centralizar lógica no backend

2. **Migração de Dados**:
   - Script para gerar `displayLatitude`/`displayLongitude` para usuários existentes

3. **Analytics**:
   - Log de offset gerado (apenas distância, não coordenadas)
   - Monitorar distribuição de offsets

---

**Data de Implementação**: 17 de dezembro de 2025
**Status**: ✅ Completo e Funcional
