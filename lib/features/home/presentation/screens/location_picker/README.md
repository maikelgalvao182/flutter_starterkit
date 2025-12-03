# Location Picker - Arquitetura Modular

## 📁 Estrutura de Arquivos

```
location_picker/
├── place_service.dart                    # Serviço isolado para Google Places API
├── location_picker_controller.dart       # Controller com toda a lógica de estado
├── location_picker_map.dart              # Widget isolado do mapa
├── location_picker_overlay.dart          # Widgets de overlay (autocomplete)
└── location_picker_page_refactored.dart  # UI principal (apenas composição)
```

## 🎯 Separação de Responsabilidades

### 1. **PlaceService** (`place_service.dart`)
**Responsabilidade**: Comunicação com Google Places API

**O que faz**:
- ✅ Autocomplete de lugares
- ✅ Busca de detalhes de um lugar
- ✅ Busca de lugares próximos (nearby)
- ✅ Reverse geocoding (coordenadas → endereço)

**O que NÃO faz**:
- ❌ Gerenciar estado
- ❌ Manipular UI
- ❌ Lidar com mapa

**Benefícios**:
- Fácil de testar (mock HTTP)
- Reutilizável em outros contextos
- Centraliza configuração de API

---

### 2. **LocationPickerController** (`location_picker_controller.dart`)
**Responsabilidade**: Gerenciar todo o estado do location picker

**O que faz**:
- ✅ Controla localização atual/selecionada
- ✅ Gerencia marcadores do mapa
- ✅ Mantém lista de lugares próximos
- ✅ Coordena autocomplete e sugestões
- ✅ Session token e debouncing
- ✅ Formata nome do local

**O que NÃO faz**:
- ❌ Renderizar UI
- ❌ Fazer HTTP diretamente
- ❌ Manipular navigation

**Benefícios**:
- Estado centralizado
- Fácil de testar
- Notifica listeners automaticamente

---

### 3. **LocationPickerMap** (`location_picker_map.dart`)
**Responsabilidade**: Renderizar e controlar o mapa

**O que faz**:
- ✅ Exibe GoogleMap
- ✅ Gerencia câmera e animações
- ✅ Trata eventos de tap

**O que NÃO faz**:
- ❌ Buscar dados
- ❌ Gerenciar estado global
- ❌ Fazer networking

**Benefícios**:
- Widget isolado e reutilizável
- Fácil de trocar (GoogleMap → AppleMaps)
- Simples de testar

---

### 4. **LocationPickerOverlay** (`location_picker_overlay.dart`)
**Responsabilidade**: Exibir overlays de autocomplete

**O que faz**:
- ✅ Renderiza lista de sugestões
- ✅ Mostra loading durante busca

**O que NÃO faz**:
- ❌ Buscar dados
- ❌ Gerenciar estado

**Benefícios**:
- Widgets stateless simples
- Fácil de estilizar
- Não causa race conditions

---

### 5. **LocationPickerPageRefactored** (`location_picker_page_refactored.dart`)
**Responsabilidade**: Compor todos os widgets e coordenar interações

**O que faz**:
- ✅ Cria e gerencia controller
- ✅ Compõe mapa + lista + overlays
- ✅ Trata callbacks de UI
- ✅ Gerencia ciclo de vida

**O que NÃO faz**:
- ❌ Lógica de negócio
- ❌ HTTP direto
- ❌ Manipulação complexa de estado

**Benefícios**:
- UI limpa e legível
- Fácil de modificar layout
- Separação clara de concerns

---

## 🔄 Fluxo de Dados

```
User Action (UI)
    ↓
LocationPickerPageRefactored (coordenação)
    ↓
LocationPickerController (estado)
    ↓
PlaceService (API)
    ↓
Controller notifica listeners
    ↓
UI atualiza automaticamente
```

## ✅ Benefícios da Arquitetura

### 🧪 Testabilidade
- **PlaceService**: Mock HTTP facilmente
- **Controller**: Testa lógica sem UI
- **Widgets**: Testa renderização isoladamente

### 🔧 Manutenibilidade
- Cada arquivo tem uma responsabilidade clara
- Mudanças ficam isoladas
- Fácil de entender o código

### 🔄 Reutilizabilidade
- **PlaceService**: Use em outros contextos
- **LocationPickerMap**: Reutilize em outras telas
- **Controller**: Compartilhe estado facilmente

### 🚀 Escalabilidade
- Adicione novas features sem bagunçar
- Troque implementações facilmente
- Migre para outras APIs sem reescrever tudo

---

## 📝 Como Usar

### Uso básico:
```dart
// No seu código
final result = await Navigator.push<LocationResult>(
  context,
  MaterialPageRoute(
    builder: (context) => const LocationPickerPageRefactored(),
  ),
);

if (result != null) {
  print('Local selecionado: ${result.formattedAddress}');
  print('Coordenadas: ${result.latLng}');
}
```

### Com localização inicial:
```dart
final result = await Navigator.push<LocationResult>(
  context,
  MaterialPageRoute(
    builder: (context) => LocationPickerPageRefactored(
      displayLocation: LatLng(-23.5505, -46.6333),
    ),
  ),
);
```

---

## 🔮 Próximos Passos

### Melhorias possíveis:
1. **Adicionar testes unitários** para cada camada
2. **Implementar debouncing** no autocomplete
3. **Cache de lugares** visitados recentemente
4. **Suporte offline** com lugares salvos
5. **Migração para Riverpod/Bloc** se necessário

---

## 🚨 Migrando do Código Antigo

Se você estava usando `LocationPickerPage` (antigo), basta trocar por:

```dart
// Antes
LocationPickerPage()

// Depois
LocationPickerPageRefactored()
```

A API é 100% compatível! ✅
