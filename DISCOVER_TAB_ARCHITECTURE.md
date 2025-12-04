# Arquitetura do Discover Tab - Análise Técnica

## 📋 Visão Geral

O **Discover Tab** é a tela principal do app que exibe um mapa interativo com eventos próximos. Esta documentação detalha a relação entre os três componentes principais e seus controllers.

---

## 🏗️ Hierarquia de Componentes

```
DiscoverTab (Widget Container)
    ├── DiscoverScreen (Wrapper do Mapa)
    │   └── AppleMapView (Mapa Apple Maps)
    │       └── AppleMapViewModel (Controller do Mapa)
    │           ├── EventMapRepository (Busca eventos)
    │           ├── EventMarkerService (Gera markers)
    │           └── UserLocationService (Localização do usuário)
    └── Botões Flutuantes
        ├── PeopleButton
        ├── ListButton
        ├── CreateButton
        └── NavigateToUserButton
```

---

## 📄 1. DiscoverTab

**Arquivo:** `lib/features/home/presentation/screens/discover_tab.dart`

### Responsabilidades:
- ✅ **Layout Container**: Gerencia o Stack de widgets (mapa + botões flutuantes)
- ✅ **Navegação**: Controla modais (CreateDrawer, ListDrawer, FindPeopleScreen)
- ✅ **Comunicação com DiscoverScreen**: Usa `GlobalKey` para chamar métodos do filho

### Controller?
❌ **NÃO TEM CONTROLLER PRÓPRIO**

O `DiscoverTab` é apenas um widget de layout. Sua única "lógica" é:
```dart
final GlobalKey<DiscoverScreenState> _discoverKey = GlobalKey<DiscoverScreenState>();

void _centerOnUser() {
  _discoverKey.currentState?.centerOnUser();
}
```

### Por que não tem controller?
- É um widget **puramente de apresentação**
- Não gerencia estado complexo
- Delega toda lógica de negócio para `DiscoverScreen` e `AppleMapView`

---

## 📄 2. DiscoverScreen

**Arquivo:** `lib/features/home/presentation/screens/discover_screen.dart`

### Responsabilidades:
- ✅ **Wrapper do AppleMapView**: Encapsula o mapa
- ✅ **Proxy para comandos de câmera**: Expõe método `centerOnUser()` para o pai
- ✅ **Gerencia GlobalKey do mapa**: Comunica-se com `AppleMapView`

### Controller?
❌ **NÃO TEM CONTROLLER PRÓPRIO**

O `DiscoverScreen` é um **intermediário mínimo**. Código completo:
```dart
class DiscoverScreenState extends State<DiscoverScreen> {
  final GlobalKey<AppleMapViewState> _mapKey = GlobalKey<AppleMapViewState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: AppleMapView(key: _mapKey),
    );
  }

  void centerOnUser() {
    _mapKey.currentState?.centerOnUser();
  }
}
```

### Por que não tem controller?
- Sua única função é **repassar comandos** para o `AppleMapView`
- Não gerencia estado de eventos, markers ou localização
- É apenas uma **camada de redirecionamento**

---

## 📄 3. AppleMapView

**Arquivo:** `lib/features/home/presentation/widgets/apple_map_view.dart`

### Responsabilidades:
- ✅ **Renderiza o Apple Maps**: Widget nativo `AppleMapController`
- ✅ **Exibe markers de eventos**: Recebe markers do ViewModel
- ✅ **Controla câmera**: Move mapa para localização do usuário
- ✅ **Gerencia interações**: Tap em markers → abre `EventCard`

### Controller?
✅ **SIM - AppleMapViewModel**

**Arquivo:** `lib/features/home/presentation/viewmodels/apple_map_viewmodel.dart`

### O que o `AppleMapViewModel` gerencia?
```dart
class AppleMapViewModel extends ChangeNotifier {
  // Estado dos markers
  Set<Annotation> _eventMarkers = {};
  
  // Estado de carregamento
  bool _isLoading = false;
  
  // Eventos carregados
  List<EventModel> _events = [];
  
  // Última localização
  LatLng? _lastLocation;
  
  // Serviços
  final EventMapRepository _eventRepository;
  final UserLocationService _locationService;
  final EventMarkerService _markerService;
}
```

### Principais métodos:
1. **`initialize()`**: Inicializa serviços de localização
2. **`loadNearbyEvents()`**: Busca eventos próximos no Firestore
3. **`_generateMarkers()`**: Converte eventos em markers do mapa
4. **`getUserLocation()`**: Obtém coordenadas do usuário

---

## 🎯 Como os eventos são listados no mapa?

### Fluxo completo:

```
1. AppleMapView.initState()
   ↓
2. _viewModel.initialize() 
   → Inicializa UserLocationService
   ↓
3. _onMapCreated() 
   → Callback quando Apple Maps está pronto
   ↓
4. _moveCameraToUserLocation()
   → Move câmera para localização do usuário
   ↓
5. _viewModel.loadNearbyEvents()
   ↓
6. EventMapRepository.getEventsWithinRadius()
   → Query no Firestore: busca eventos num raio de X km
   ↓
7. EventMarkerService.generateMarkersForEvents()
   → Converte eventos em Annotation (markers)
   ↓
8. _viewModel notifica listeners
   ↓
9. AppleMapView.build() reconstrói com novos markers
   ↓
10. Apple Maps exibe pins no mapa
```

### Query dos eventos:
```dart
// EventMapRepository
Future<List<EventModel>> getEventsWithinRadius(LatLng center, double radiusKm) async {
  final querySnapshot = await _eventsRef
      .where('latitude', isGreaterThan: minLat)
      .where('latitude', isLessThan: maxLat)
      .get();
  
  // Filtra por distância real (Haversine)
  return events.where((e) => distance <= radiusKm).toList();
}
```

---

## 📄 4. EventCard

**Arquivo:** `lib/features/home/presentation/widgets/event_card/event_card.dart`

### Responsabilidades:
- ✅ **Exibe detalhes do evento**: Criador, localização, data, emoji
- ✅ **Gerencia candidaturas**: Botão "Participar" ou "Ver Chat"
- ✅ **Navega para o chat**: Se aprovado, abre `ChatScreenRefactored`

### Controller?
✅ **SIM - EventCardController**

**Arquivo:** `lib/features/home/presentation/widgets/event_card/event_card_controller.dart`

### O que o `EventCardController` gerencia?
```dart
class EventCardController extends ChangeNotifier {
  // Dados do evento
  String? _creatorFullName;
  String? _locationName;
  String? _emoji;
  String? _activityText;
  DateTime? _scheduleDate;
  
  // Estado de candidatura
  EventApplicationModel? _userApplication;
  bool _isApplying = false;
  
  // Participantes aprovados
  List<Map<String, dynamic>> _approvedParticipants = [];
}
```

### Principais métodos:
1. **`load()`**: Carrega dados do evento (ANTES de abrir o card)
2. **`_loadEventData()`**: Busca dados no Firestore (`events/{eventId}`)
3. **`_loadUserApplication()`**: Verifica se o usuário já aplicou
4. **`applyToEvent()`**: Cria candidatura no Firestore
5. **`_loadApprovedParticipants()`**: Busca lista de participantes

### Fluxo de candidatura:
```
1. Usuário toca em marker do mapa
   ↓
2. AppleMapView._onMarkerTap(eventId)
   ↓
3. Cria EventCardController e chama .load()
   ↓
4. Controller busca:
   - Dados do evento
   - Application do usuário
   - Lista de participantes
   ↓
5. Abre EventCard com dados carregados
   ↓
6. Usuário pressiona botão
   ↓
7. EventCardController.applyToEvent()
   → Cria documento em event_applications
   ↓
8. Se evento é "open", auto-aprova
   ↓
9. Navega para ChatScreenRefactored
```

---

## 🔄 Resumo de Controllers

| Componente | Tem Controller? | Qual? | O que gerencia? |
|------------|----------------|-------|-----------------|
| **DiscoverTab** | ❌ NÃO | - | Layout de botões flutuantes |
| **DiscoverScreen** | ❌ NÃO | - | Proxy para AppleMapView |
| **AppleMapView** | ✅ SIM | `AppleMapViewModel` | Eventos, markers, localização |
| **EventCard** | ✅ SIM | `EventCardController` | Dados do evento, candidaturas |

---

## 🎯 Padrão Arquitetural

O código segue **MVVM (Model-View-ViewModel)**:

```
View (Widget)         ViewModel (Controller)       Model (Repository)
─────────────         ───────────────────────      ───────────────────
AppleMapView    ←→    AppleMapViewModel      ←→    EventMapRepository
                                              ←→    EventMarkerService
                                              ←→    UserLocationService

EventCard       ←→    EventCardController    ←→    EventRepository
                                              ←→    EventApplicationRepository
                                              ←→    UserRepository
```

### Princípios aplicados:
✅ **Separation of Concerns**: UI separada de lógica de negócio  
✅ **Single Responsibility**: Cada controller tem uma responsabilidade clara  
✅ **Dependency Injection**: Repositórios injetados nos controllers  
✅ **Reactive UI**: `ChangeNotifier` notifica mudanças de estado  

---

## 🚀 Melhorias Sugeridas

### 1. DiscoverScreen poderia ser removido
Atualmente é apenas um wrapper desnecessário. Poderíamos fazer:
```dart
// DiscoverTab
Stack(
  children: [
    AppleMapView(key: _mapKey),
    // ... botões
  ],
)
```

### 2. EventCard carrega dados tarde demais
Problema atual:
```dart
// AppleMapView
void _onMarkerTap(String eventId) async {
  final controller = EventCardController(eventId: eventId);
  await controller.load(); // ⚠️ Usuário espera
  showModalBottomSheet(...);
}
```

**Solução**: Pré-carregar dados quando markers são criados:
```dart
// AppleMapViewModel
Future<void> _generateMarkers() async {
  for (final event in _events) {
    // Já tem dados do evento aqui!
    _eventMarkers.add(
      Annotation(
        annotationId: AnnotationId(event.id),
        // ... dados já prontos
      ),
    );
  }
}
```

### 3. Falta tratamento de erros
Se `loadNearbyEvents()` falhar, o mapa fica vazio sem feedback.

**Solução**: Adicionar estado de erro no ViewModel:
```dart
class AppleMapViewModel extends ChangeNotifier {
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadNearbyEvents() async {
    try {
      _events = await _eventRepository.getEventsWithinRadius(...);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar eventos: $e';
    }
    notifyListeners();
  }
}
```

---

## 📚 Arquivos Relacionados

### Core:
- `lib/features/home/presentation/screens/discover_tab.dart`
- `lib/features/home/presentation/screens/discover_screen.dart`
- `lib/features/home/presentation/widgets/apple_map_view.dart`

### Controllers:
- `lib/features/home/presentation/viewmodels/apple_map_viewmodel.dart`
- `lib/features/home/presentation/widgets/event_card/event_card_controller.dart`

### Repositories:
- `lib/features/home/data/repositories/event_map_repository.dart`
- `lib/features/home/data/repositories/event_repository.dart`
- `lib/features/home/data/repositories/event_application_repository.dart`

### Services:
- `lib/features/home/presentation/services/event_marker_service.dart`
- `lib/features/home/data/services/user_location_service.dart`

---

## 🎓 Conclusão

**DiscoverTab** é uma arquitetura em camadas:
1. **Tab Container** (sem controller) → Layout
2. **Screen Wrapper** (sem controller) → Proxy
3. **Map View** (com ViewModel) → Lógica de eventos/markers
4. **Event Card** (com Controller) → Lógica de candidatura

A separação é clara e segue boas práticas, mas há oportunidades de simplificação (remover `DiscoverScreen`) e otimização (pré-carregar dados do card).
