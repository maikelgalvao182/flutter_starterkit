# 📋 Módulo Edit Profile - Partiu

> **Código modular, limpo e performático seguindo padrões MVVM**

---

## 🎯 Visão Geral

Módulo completo de edição de perfil que utiliza **Firestore diretamente** (sem camada de API), seguindo as melhores práticas de arquitetura Flutter.

---

## 📁 Estrutura de Arquivos

```
features/profile/
├── data/
│   ├── repositories/
│   │   └── profile_repository.dart        # Acesso direto ao Firestore
│   └── services/
│       └── image_upload_service.dart      # Upload para Firebase Storage
├── domain/
│   ├── models/
│   │   ├── profile_form_data.dart         # Modelo imutável de dados
│   │   └── edit_profile_state.dart        # Estados e Commands
│   └── repositories/
│       └── profile_repository_interface.dart  # Contrato do repositório
├── presentation/
│   ├── screens/
│   │   ├── edit_profile_screen.dart       # Tela principal (View)
│   │   └── profile_screen_router.dart     # Navegação centralizada
│   ├── viewmodels/
│   │   └── edit_profile_view_model.dart   # Lógica de negócio
│   └── widgets/
│       ├── edit_profile_app_bar.dart      # AppBar customizada
│       └── profile_photo_widget.dart      # Widget de foto
└── di/
    └── profile_dependency_provider.dart    # Injeção de dependências
```

---

## 🏗️ Arquitetura - MVVM Pattern

### **View (UI)**
- `EditProfileScreen`: Tela "burra" que apenas renderiza
- Gerencia `TextEditingController`s localmente
- Delega toda lógica ao ViewModel
- Executa commands (toast, navegação)

### **ViewModel (Lógica)**
- `EditProfileViewModel`: Gerencia estado e lógica de negócio
- **Não depende** de `BuildContext`
- Usa `ChangeNotifier` para notificar mudanças
- Emite `Commands` para ações de UI

### **Repository (Dados)**
- `ProfileRepository`: Acessa Firestore diretamente
- Interface `IProfileRepository` para testabilidade
- Operações: fetch, update, updatePhoto, updateLocation

### **Services**
- `ImageUploadService`: Upload de imagens para Firebase Storage
- Seleção de imagens (galeria/câmera)
- Compressão e otimização

---

## 🔄 Fluxo de Dados

```
User Action (View)
    ↓
ViewModel (valida + processa)
    ↓
Repository (Firestore)
    ↓
ViewModel (atualiza estado)
    ↓
View (rebuilds via ListenableBuilder)
```

---

## ✅ Boas Práticas Implementadas

### **1. Naming Conventions**
- ✅ `camelCase` para variáveis, métodos e campos Firestore
- ✅ `PascalCase` para classes e widgets
- ✅ **Sem `snake_case`** (exceto constantes globais)

### **2. Performance**
- ✅ Widgets `const` sempre que possível
- ✅ `RepaintBoundary` para isolar repaints
- ✅ Controllers gerenciados localmente pela View
- ✅ Estado imutável (`ProfileFormData`)

### **3. Modularidade**
- ✅ Separação clara de responsabilidades
- ✅ Widgets pequenos e reutilizáveis
- ✅ Lógica isolada no ViewModel
- ✅ Repository com interface para testes

### **4. State Management**
- ✅ Estados explícitos (`Initial`, `Loading`, `Loaded`, `Error`)
- ✅ Commands para separar lógica de UI
- ✅ `ChangeNotifier` para reatividade

---

## 🚀 Como Usar

### **1. Navegar para EditProfile**

```dart
await ProfileScreenRouter.navigateToEditProfile(context);
```

### **2. Integração Automática**

O módulo já está integrado com:
- ✅ `ProfileTab` (botão "Editar Perfil")
- ✅ `AppState` (atualização automática após salvar)
- ✅ Firebase Firestore e Storage

### **3. Atualização de Foto**

```dart
// O upload é gerenciado automaticamente
// Basta tocar na foto de perfil
```

---

## 🧪 Testabilidade

### **Repository Interface**

```dart
// Mock do repository para testes
class MockProfileRepository implements IProfileRepository {
  @override
  Future<Map<String, dynamic>?> fetchProfileData(String userId) async {
    return {'userFullname': 'Test User'};
  }
  // ...
}
```

### **ViewModel Testável**

```dart
// Injeção de dependências facilita testes
final viewModel = EditProfileViewModel(
  profileRepository: mockRepository,
  firebaseAuth: mockAuth,
);
```

---

## 📊 Campos Suportados

### **Dados Básicos**
- Nome completo
- Bio
- Profissão
- Escola
- Gênero
- Data de nascimento

### **Localização**
- Cidade
- Estado
- País
- GeoPoint

### **Contato**
- Email
- Telefone

### **Redes Sociais**
- Website
- Instagram
- TikTok
- YouTube
- Pinterest
- Vimeo

### **Vendor (exclusivo)**
- Preços (inicial, média)
- Anos de experiência
- Serviços oferecidos
- Categorias de ofertas

### **Mídia**
- Fotos (galeria)
- Vídeos

---

## 🔥 Integração Firebase

### **Firestore**
```
users/{userId}
├── userFullname
├── userBio
├── userJobTitle
├── instagram
├── website
└── ...
```

### **Storage**
```
users/{userId}/
├── profile/
│   └── {timestamp}.jpg
├── gallery/
│   └── {timestamp}.jpg
└── videos/
    └── {timestamp}.mp4
```

---

## 🎨 UI/UX

- **Design iOS-style** com CupertinoButton
- **Loading states** com CupertinoActivityIndicator
- **Toast messages** para feedback
- **Unsaved changes** detection
- **Responsive layout**

---

## 🔧 Próximas Melhorias

- [ ] Adicionar tabs (Personal, Social, Offers, Mídia)
- [ ] Implementar validação de campos
- [ ] Adicionar compressão de imagens
- [ ] Galeria de fotos completa
- [ ] Upload de vídeos
- [ ] Crop de imagens
- [ ] Suporte offline (cache local)

---

## 📝 Convenções do Projeto

### **Sempre use:**
- `camelCase` para campos Firestore
- Modelos imutáveis
- Injeção de dependências
- Command Pattern para UI actions
- AppLogger para logs estruturados

### **Nunca:**
- ❌ Lógica no `build()`
- ❌ `snake_case` em Dart/Firestore
- ❌ ViewModel com `BuildContext`
- ❌ Controllers no ViewModel
- ❌ Estado mutável

---

## 🤝 Contribuindo

1. Siga as **instruções básicas** em `.github/instructions/`
2. Use o **padrão MVVM** estabelecido
3. Mantenha widgets **pequenos e focados**
4. Adicione **logs** com `AppLogger`
5. Escreva **código autoexplicativo**

---

**📌 Lembre-se:** Código limpo não é sobre linhas, mas sobre **clareza e manutenibilidade**.
