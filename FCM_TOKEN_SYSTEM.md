# FCM Token Management System

## 📱 Visão Geral

Sistema centralizado de gerenciamento de **FCM tokens** para push notifications, com suporte a múltiplos dispositivos por usuário.

---

## 🏗️ Arquitetura

### Nova Coleção: `DeviceTokens`

Substituiu o campo `fcm_token` na coleção `Users` por uma coleção dedicada que suporta múltiplos dispositivos.

```
DeviceTokens/
  └── {userId}_{deviceId}/           ← Document ID único por dispositivo
      ├── userId: string              ← ID do usuário
      ├── token: string               ← FCM token atual
      ├── deviceId: string            ← Android ID / iOS identifierForVendor
      ├── deviceName: string          ← Ex: "Samsung Galaxy S21"
      ├── platform: "android" | "ios" ← Sistema operacional
      ├── createdAt: timestamp        ← Primeira vez que o token foi salvo
      ├── updatedAt: timestamp        ← Última vez que o token mudou
      └── lastUsedAt: timestamp       ← Último login/uso do app
```

---

## 🔑 Serviço: `FcmTokenService`

Localizado em: `lib/features/notifications/services/fcm_token_service.dart`

### Métodos Principais

#### `initialize()`
Inicializa o serviço após o login do usuário:
- Obtém FCM token do dispositivo
- Obtém device ID único (Android ID ou iOS identifierForVendor)
- Salva no Firestore
- Configura listener para token refresh automático

```dart
// Chamado automaticamente no AuthSyncService após login
await FcmTokenService.instance.initialize();
```

#### `refreshToken()`
Força atualização manual do token:
- Deleta token antigo
- Solicita novo token
- Salva no Firestore

```dart
await FcmTokenService.instance.refreshToken();
```

#### `clearTokens()`
Remove todos os tokens do usuário (logout):
- Busca todos os tokens do usuário
- Remove em batch
- Limpa cache local

```dart
// Chamado automaticamente no AuthSyncService.signOut()
await FcmTokenService.instance.clearTokens();
```

#### `getTokensInfo()`
Obtém informações de todos os dispositivos do usuário:

```dart
final devices = await FcmTokenService.instance.getTokensInfo();
// [
//   {
//     'deviceId': 'abc123',
//     'deviceName': 'iPhone 14 Pro',
//     'platform': 'ios',
//     'createdAt': Timestamp,
//     'lastUsedAt': Timestamp,
//   },
//   ...
// ]
```

---

## 🔄 Integração com AuthSyncService

O `FcmTokenService` é inicializado automaticamente no fluxo de autenticação:

**`lib/core/services/auth_sync_service.dart`:**

```dart
// Após carregar dados do usuário do Firestore
if (!_notificationServiceInitialized) {
  NotificationsCounterService.instance.initialize();
  
  // ✅ Inicializa FCM Token Service
  await FcmTokenService.instance.initialize();
  
  _notificationServiceInitialized = true;
}
```

**No logout:**

```dart
Future<void> signOut() async {
  // ...
  
  // ✅ Limpa tokens FCM antes de deslogar
  await FcmTokenService.instance.clearTokens();
  
  await SessionManager.instance.logout();
  await FirebaseAuth.instance.signOut();
}
```

---

## ☁️ Cloud Functions Atualizadas

As Cloud Functions para push notifications foram atualizadas para buscar tokens da nova coleção `DeviceTokens`.

### Chat 1-1: `onPrivateMessageCreated`

**Antes:**
```typescript
// Buscava token em Users/{userId}.fcm_token
const receiverDoc = await admin.firestore()
  .collection("Users")
  .doc(receiverId)
  .get();
const fcmToken = receiverDoc.data()?.fcm_token;
```

**Depois:**
```typescript
// Busca todos os tokens do receiver
const tokensSnapshot = await admin.firestore()
  .collection("DeviceTokens")
  .where("userId", "==", receiverId)
  .get();

const fcmTokens = tokensSnapshot.docs
  .map((doc) => doc.data().token)
  .filter((token) => token && token.length > 0);

// Envia push para todos os dispositivos
await admin.messaging().sendEachForMulticast({
  tokens: fcmTokens,
  notification: { ... },
  data: { ... },
});
```

### Chat de Grupo: `onEventChatMessageCreatedPush`

**Antes:**
```typescript
// Buscava tokens em Users collection com where...in (max 10)
const userDocs = await admin.firestore()
  .collection("Users")
  .where(admin.firestore.FieldPath.documentId(), "in", receivers.slice(0, 10))
  .get();
```

**Depois:**
```typescript
// Busca tokens em batch (max 10 usuários por batch)
for (let i = 0; i < receivers.length; i += 10) {
  const batch = receivers.slice(i, i + 10);
  const tokensSnapshot = await admin.firestore()
    .collection("DeviceTokens")
    .where("userId", "in", batch)
    .get();
  
  tokensSnapshot.docs.forEach((doc) => {
    tokens.push(doc.data().token);
  });
}

// Envia push multicast para todos
await admin.messaging().sendEachForMulticast({ ... });
```

---

## 🗑️ Token Cleanup Automático

Os tokens inválidos são removidos automaticamente quando o FCM retorna erro:

```typescript
if (response.failureCount > 0) {
  const batch = admin.firestore().batch();
  response.responses.forEach((result, index) => {
    if (!result.success && result.error) {
      const errorCode = result.error.code;
      if (
        errorCode === "messaging/invalid-registration-token" ||
        errorCode === "messaging/registration-token-not-registered"
      ) {
        const tokenDoc = tokensSnapshot.docs[index];
        batch.delete(tokenDoc.ref); // Remove token inválido
      }
    }
  });
  await batch.commit();
}
```

---

## 🔐 Firestore Rules

**Arquivo:** `rules/device_tokens.rules`

```plaintext
match /DeviceTokens/{tokenId} {
  // Permite leitura apenas se for o dono do token
  allow read: if isSignedIn() && resource.data.userId == request.auth.uid;
  
  // Permite criação/atualização apenas se o userId no documento for o próprio usuário
  allow create, update: if isSignedIn() && request.resource.data.userId == request.auth.uid;
  
  // Permite exclusão apenas se for o dono do token
  allow delete: if isSignedIn() && resource.data.userId == request.auth.uid;
}
```

**Deploy:**
```bash
./build-rules.sh
firebase deploy --only firestore:rules
```

---

## 📊 Benefícios

### ✅ Suporte a Múltiplos Dispositivos
- Usuário pode ter iPhone + iPad + Android tablet
- Cada dispositivo recebe push notifications
- Tokens gerenciados independentemente

### ✅ Cleanup Automático
- Tokens inválidos removidos nas Cloud Functions
- Tokens antigos não poluem a base

### ✅ Rastreabilidade
- `createdAt`: Quando o dispositivo foi registrado
- `updatedAt`: Última vez que o token mudou
- `lastUsedAt`: Último uso do app
- `deviceName` e `platform`: Info do dispositivo

### ✅ Escalabilidade
- Não sobrecarrega a coleção `Users`
- Facilita queries por plataforma
- Permite analytics de dispositivos

---

## 🔄 Migração do Sistema Antigo

### Sistema Antigo (Deprecado)
```
Users/{userId}
  └── fcm_token: string  ❌ Apenas 1 dispositivo
```

### Sistema Novo
```
DeviceTokens/{userId}_{deviceId}
  ├── userId: string
  ├── token: string
  ├── deviceId: string
  ├── deviceName: string
  ├── platform: string
  ├── createdAt: timestamp
  ├── updatedAt: timestamp
  └── lastUsedAt: timestamp
```

**Migração automática:**
- Novos logins salvam em `DeviceTokens` automaticamente
- Cloud Functions buscam apenas em `DeviceTokens`
- Campo `fcm_token` em `Users` não é mais usado

---

## 🧪 Como Testar

### 1. Login no App
```dart
// FcmTokenService.initialize() é chamado automaticamente
// Verifique os logs:
// 🔑 [FCM Token] Inicializando serviço...
// 📱 [FCM Token] Device ID: abc123
// 🔑 [FCM Token] Token obtido: dKj8fH3kL9m...
// ✅ [FCM Token] Novo token salvo no Firestore
```

### 2. Verificar no Firestore Console
```
DeviceTokens/
  └── userId_deviceId123/
      ├── userId: "user123"
      ├── token: "dKj8fH3kL9m..."
      ├── deviceId: "abc123"
      ├── deviceName: "iPhone 14 Pro"
      ├── platform: "ios"
      └── ...
```

### 3. Enviar Mensagem de Chat
- Abrir chat com outro usuário
- Enviar mensagem
- Verificar logs da Cloud Function:
```
📬 [ChatPush] Nova mensagem 1-1
📱 [ChatPush] Encontrados 2 dispositivo(s)
🚀 [ChatPush] Enviando push para 2 dispositivo(s)
✅ [ChatPush] Push enviado com sucesso
   Success: 2
   Failure: 0
```

### 4. Logout
```dart
await authSync.signOut();

// Logs esperados:
// 🗑️ [FCM Token] Removendo tokens do usuário user123
// ✅ [FCM Token] 2 token(s) removido(s)
```

---

## 📚 Referências

- **Serviço:** `lib/features/notifications/services/fcm_token_service.dart`
- **Integração:** `lib/core/services/auth_sync_service.dart`
- **Cloud Functions:** `functions/src/chatPushNotifications.ts`
- **Rules:** `rules/device_tokens.rules`
- **Documentação Chat Push:** `CHAT_PUSH_NOTIFICATIONS.md`
