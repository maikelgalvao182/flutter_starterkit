# Integração Didit Verification - Documentação Completa

**Data:** 11 de dezembro de 2025  
**Status:** ✅ Implementado e Ativo  
**Plataformas:** iOS e Android

## 📋 Visão Geral

Implementação completa do sistema de verificação de identidade via **Didit** usando WebView nativo para iOS e Android. O Didit oferece verificação biométrica avançada e é a **única solução de verificação** do app.

> **Nota:** Esta implementação substituiu completamente a integração anterior do FACEIO.

## 🎯 Componentes Implementados

### 1. Dependências Adicionadas (`pubspec.yaml`)

```yaml
# WebView
flutter_inappwebview: ^6.0.0
permission_handler: ^11.0.0
```

### 2. Modelo de Dados

**Arquivo:** `lib/core/models/didit_session.dart`

Modelo para gerenciar sessões de verificação:

```dart
class DiditSession {
  final String sessionId;      // ID único da sessão
  final String userId;          // ID do usuário
  final String url;             // URL da sessão de verificação
  final String workflowId;      // ID do workflow do Didit
  final DateTime createdAt;     // Data de criação
  final DateTime? completedAt;  // Data de conclusão
  final String status;          // 'pending', 'completed', 'failed', 'expired'
  final String? vendorData;     // Dados customizados
  final Map<String, dynamic>? result; // Resultado da verificação
}
```

**Arquivo:** `lib/core/models/face_verification.dart`

Modelo atualizado para armazenar verificações (mantém nome por compatibilidade):

```dart
/// Modelo para armazenar dados de verificação de identidade via Didit
class FaceVerification {
  final String userId;
  final String facialId;  // ID da verificação do Didit
  final DateTime verifiedAt;
  final String status;
  final String? gender;
  final int? age;
  final Map<String, dynamic>? details;
}
```

### 3. Serviço de Verificação

**Arquivo:** `lib/core/services/didit_verification_service.dart`

Serviço singleton para gerenciar a API do Didit:

#### Funcionalidades Principais:

- ✅ **Configuração via Firestore**: Busca API key e workflow ID de `AppInfo/didit`
- ✅ **Criação de Sessões**: Cria sessões de verificação via API do Didit
- ✅ **Gerenciamento de Sessões**: Salva e atualiza sessões no Firestore
- ✅ **Cache Inteligente**: Cacheia configurações para performance
- ✅ **Stream de Mudanças**: Observa status em tempo real

### Configuração no Firestore

```
AppInfo/
  └── didio/
      ├── api_key: "sua-api-key-do-didit"
      ├── app_id: "seu-app-id"
      ├── callback_url: "https://partiu.app/verification/callback" (opcional)
      └── webhook_secret: "seu-webhook-secret" (para webhooks)

DiditSessions/
  └── {sessionId}/
      ├── userId: "user-id"
      ├── url: "https://verification.didit.me/..."
      ├── workflowId: "workflow-id"
      ├── createdAt: Timestamp
      ├── completedAt: Timestamp (opcional)
      ├── status: "pending|completed|failed|expired"
      ├── vendorData: string (opcional)
      └── result: Map (opcional)
```

### 4. Tela de Verificação

**Arquivo:** `lib/screens/verification/didit_verification_screen.dart`

Tela com WebView otimizado para verificação:

#### Características:

- ✅ **InAppWebView**: WebView completo com suporte a mídia
- ✅ **Permissões Automáticas**: Concede câmera/microfone automaticamente
- ✅ **Interceptação de Callback**: Detecta conclusão da verificação
- ✅ **Estados de UI**: Loading, Erro, WebView
- ✅ **Integração com FaceVerificationService**: Salva resultados automaticamente
- ✅ **Stream de Status**: Monitora mudanças em tempo real

#### Configurações do WebView:

```dart
InAppWebViewSettings(
  userAgent: "Mozilla/5.0 (Linux; Android 10; Mobile)...",
  mediaPlaybackRequiresUserGesture: false,
  allowsInlineMediaPlayback: true,
  iframeAllow: "camera; microphone",
  iframeAllowFullscreen: true,
  javaScriptEnabled: true,
  domStorageEnabled: true,
)
```

### 5. Atualização do FaceVerificationService

**Arquivo:** `lib/core/services/face_verification_service.dart`

Serviço simplificado para salvar apenas verificações do Didit:

```dart
/// Serviço para gerenciar verificação de identidade via Didit
class FaceVerificationService {
  Future<bool> saveVerification({
    required String facialId,
    required Map<String, dynamic> userInfo,
  }) async {
    // Salva com verification_type = 'didit'
    // Atualiza user_is_verified = true
  }
}
```

#### Campos no Firestore:

```
Users/{userId}/
  ├── user_is_verified: true
  ├── verified_at: Timestamp
  ├── facial_id: "id-da-verificacao"
  └── verification_type: "didit"

FaceVerifications/{userId}/
  ├── userId: string
  ├── facialId: string
  ├── verifiedAt: Timestamp
  ├── status: "verified"
  ├── details: {
  │     verification_type: "didit",
  │     verification_date: ISO8601,
  │     ...outros dados
  │   }
```

## 🔧 Configurações de Plataforma

### Android

**Arquivo:** `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Permissões para Didit -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.VIDEO_CAPTURE" />
<uses-permission android:name="android.permission.AUDIO_CAPTURE" />

<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

<!-- Provider do InAppWebView -->
<provider
  android:name="com.pichillilorenzo.flutter_inappwebview_android.InAppWebViewFileProvider"
  android:authorities="${applicationId}.flutter_inappwebview_android.fileprovider"
  android:exported="false"
  android:grantUriPermissions="true">
  <meta-data
    android:name="android.support.FILE_PROVIDER_PATHS"
    android:resource="@xml/provider_paths"
  />
</provider>
```

**Arquivo:** `android/app/src/main/res/xml/provider_paths.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-path name="external_files" path="."/>
    <root-path name="root" path="." />
    <files-path name="files" path="." />
    <cache-path name="cache" path="." />
    <external-files-path name="external-files" path="." />
    <external-cache-path name="external-cache" path="." />
</paths>
```

### iOS

**Arquivo:** `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Precisamos acessar sua câmera para verificação facial de segurança.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Precisamos acessar seu microfone para verificação de segurança.</string>
<key>io.flutter.embedded_views_preview</key>
<true/>
```

✅ Já estava configurado no projeto!

## 🚀 Como Usar
### 1. Configurar no Firestore

Criar documento em `AppInfo/didio`:

```javascript
{
  "api_key": "sua-api-key-do-didit",
  "app_id": "seu-app-id",
  "callback_url": "https://partiu.app/verification/callback" // opcional
}
```
```

### 2. Navegar para Tela de Verificação

```dart
import 'package:partiu/screens/verification/didit_verification_screen.dart';

// Navegação simples
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DiditVerificationScreen(),
  ),
);

if (result == true) {
  // Verificação concluída com sucesso
  print('Usuário verificado!');
} else {
  // Verificação falhou ou foi cancelada
  print('Verificação não concluída');
}
```

### 3. Verificar Status

```dart
import 'package:partiu/core/services/face_verification_service.dart';

// Verificar se usuário está verificado
final isVerified = await FaceVerificationService.instance.isUserVerified();

// Observar mudanças no status
FaceVerificationService.instance
    .watchVerificationStatus(userId)
    .listen((isVerified) {
  print('Status de verificação: $isVerified');
});
```

### 4. Widget de Verificação

O app já possui um card pronto para usar:

```dart
import 'package:partiu/shared/widgets/verification_card.dart';

// Usar o card (já integrado com DiditVerificationScreen)
VerificationCard(
  onVerificationComplete: () {
    print('Verificação completa!');
  },
)
```

## 🔄 Fluxo de Verificação

```
1. Usuário clica em "Verificar Identidade"
   ↓
2. App abre DiditVerificationScreen
   ↓
3. DiditVerificationService cria sessão via API
   ↓
4. Sessão é salva no Firestore (DiditSessions)
   ↓
5. URL da sessão é carregada no WebView
   ↓
6. Usuário completa verificação no Didit
   ↓
7. Didit redireciona para callback URL
   ↓
8. App intercepta callback e busca resultado
   ↓
9. Resultado é salvo via FaceVerificationService
   ↓
10. User.user_is_verified = true
   ↓
11. Tela retorna sucesso (true)
```

## 🔄 Migração do FACEIO

### Arquivos Removidos

- ❌ `public/face-verification.html`
- ❌ `lib/features/profile/presentation/screens/face_verification_screen.dart`
- ❌ `FACE_VERIFICATION_INTEGRATION.md`
- ❌ `FACEIO_WEBHOOK_INTEGRATION.md`

### Arquivos Atualizados

- ✅ `lib/core/services/face_verification_service.dart` - Simplificado para Didit apenas
- ✅ `lib/core/models/face_verification.dart` - Comentários atualizados
- ✅ `lib/shared/widgets/verification_card.dart` - Usa DiditVerificationScreen

### Compatibilidade de Dados

Os dados de verificação continuam sendo salvos nas mesmas coleções:
- `FaceVerifications/{userId}` - Mantido por compatibilidade
- `Users/{userId}.user_is_verified` - Mesmo campo

Usuários verificados anteriormente pelo FACEIO permanecem verificados.

## 📡 Webhooks e Callbacks

O Didit pode chamar uma Cloud Function quando a verificação for concluída:

```typescript
// Exemplo de Cloud Function para webhook
export const diditWebhook = functions.https.onRequest(async (req, res) => {
  const { session_id, status, result } = req.body;
  
  // Atualizar sessão no Firestore
  await admin.firestore()
    .collection('DiditSessions')
    .doc(session_id)
    .update({
      status: status,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      result: result
    });
  
  res.status(200).send({ success: true });
});
```

## 🔒 Segurança

### ⚠️ IMPORTANTE: API Key

**Atualmente**, a API key do Didit está sendo usada no cliente. Para produção:

1. **Mover para Cloud Function**: Criar sessões via função do backend
2. **Proteger API key**: Não expor no app
3. **Validar no servidor**: Processar callbacks no backend

### Exemplo de Cloud Function:

```typescript
export const createDiditSession = functions.https.onCall(async (data, context) => {
  // Validar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }
  
  const userId = context.auth.uid;
  
  // Buscar config do Firestore
  const config = await admin.firestore()
    .collection('AppInfo')
    .doc('didit')
    .get();
  
  const { api_key, workflow_id, callback_url } = config.data();
  
  // Criar sessão via API do Didit
  const response = await fetch('https://verification.didit.me/v2/session/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Api-Key': api_key
    },
    body: JSON.stringify({
      workflow_id: workflow_id,
      vendor_data: userId,
      callback: callback_url
    })
  });
  
  const session = await response.json();
  
  // Salvar no Firestore
  await admin.firestore()
    .collection('DiditSessions')
    .doc(session.id)
    .set({
      userId: userId,
      url: session.url,
      workflowId: workflow_id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
      vendorData: userId
    });
  
  return { sessionId: session.id, url: session.url };
});
```

## 🧪 Testes

### Testar no Dispositivo:

1. ✅ Instalar dependências: `flutter pub get`
2. ✅ Configurar Firestore com credenciais do Didit
3. ✅ Executar no dispositivo físico (simulador pode não ter câmera)
4. ✅ Navegar para `DiditVerificationScreen`
5. ✅ Concluir verificação facial
6. ✅ Verificar que `user_is_verified = true`

### Logs Úteis:

```dart
// DiditVerificationService
'Criando sessão de verificação...'
'Sessão criada: {sessionId}'
'Status da sessão: {status}'

// DiditVerificationScreen
'WebView criado'
'Carregando: {url}'
'Página carregada: {url}'
'Permissão solicitada: {resources}'
'Callback recebido: {url}'
'Verificação concluída com sucesso'

// FaceVerificationService
'Verificação facial salva com sucesso (didit)'
```

## 📊 Comparação: Didit vs FACEIO (Removido)

| Característica | Didit (Atual) | FACEIO (Anterior) |
|---------------|---------------|-------------------|
| Tipo | WebView externo | JS SDK integrado |
| Implementação | URL em WebView | Script na página |
| Controle | Didit gerencia UI | Total controle |
| Manutenção | Mais simples | Mais complexo |
| Performance | Depende da web | Nativa |
| Segurança | Alta (servidor) | Média (cliente) |
| Custo | Pago (enterprise) | Freemium |
| Status | ✅ Ativo | ❌ Removido |

## 🎨 Customizações Possíveis

1. **UI da Tela**: Alterar cores, mensagens, layout
2. **Timeout**: Adicionar timer para sessões
3. **Retry Logic**: Implementar tentativas automáticas
4. **Analytics**: Rastrear sucesso/falha
5. **Notificações**: Alertar conclusão via push

## 📝 Próximos Passos

- [ ] Mover criação de sessão para Cloud Function
- [ ] Implementar webhook do Didit
- [ ] Adicionar analytics de conversão
- [ ] Criar testes automatizados
- [ ] Documentar fluxo de erro detalhado
- [ ] Adicionar retry automático em falhas
- [ ] Implementar timeout de sessão

## 🐛 Troubleshooting

### Permissões Negadas

```dart
// Solicitar permissões antes de abrir tela
await Permission.camera.request();
await Permission.microphone.request();
```

### WebView não Carrega

- Verificar conexão de internet
- Verificar se URL da sessão é válida
- Verificar logs do WebView

### Callback não Funciona

- Verificar URL de callback configurada
- Verificar interceptação de URL no código
- Verificar logs do Didit

## 📚 Referências

- [Didit Documentation](https://docs.didit.me/)
- [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview)
- [permission_handler](https://pub.dev/packages/permission_handler)
- [Exemplo de Referência](flutter-didit-verification-webview-main)

---

**Implementado por:** GitHub Copilot  
**Data:** 11 de dezembro de 2025
