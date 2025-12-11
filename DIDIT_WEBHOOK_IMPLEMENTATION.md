# Webhook Didit - Implementação Completa

**Data:** 11 de dezembro de 2025  
**Status:** ✅ Implementado  
**Foco:** ID Verification

## 📋 Visão Geral

Sistema completo de webhooks do Didit para receber notificações em tempo real sobre verificações de identidade. O webhook é processado de forma segura com validação HMAC e salva automaticamente verificações aprovadas.

## 🎯 Componentes Implementados

### 1. Modelos de Dados

**Arquivo:** `lib/core/models/didit_webhook.dart`

Modelos TypeScript-safe para webhook:

```dart
class DiditWebhook {
  final String sessionId;
  final String status;
  final String webhookType;  // 'status.updated' | 'data.updated'
  final DiditDecision? decision;
  
  bool get isApproved;
  bool get hasApprovedIdVerification;
}

class DiditDecision {
  final String sessionId;
  final String status;
  final DiditIdVerification? idVerification;
  final List<DiditReview>? reviews;
}

class DiditIdVerification {
  final String status;  // 'Approved' | 'Declined' | 'In Review'
  final String? documentType;
  final String? documentNumber;
  final String? fullName;
  final String? dateOfBirth;
  final int? age;
  final String? gender;
  final String? nationality;
  final String? portraitImage;
  
  bool get isApproved;
}
```

### 2. Cloud Function

**Arquivo:** `functions/didit_webhook.js`

Função serverless para processar webhooks:

#### Funcionalidades:

- ✅ **Validação de Assinatura HMAC-SHA256**
- ✅ **Verificação de Timestamp** (máximo 5 minutos)
- ✅ **Histórico de Webhooks** (salva em `DiditWebhooks`)
- ✅ **Atualização de Sessão** (atualiza `DiditSessions`)
- ✅ **Salvamento Automático** (cria `FaceVerifications` e atualiza `Users`)
- ✅ **Retry Policy** (2 tentativas automáticas pelo Didit)
- ✅ **Função de Reprocessamento** (para casos especiais)

## 🔐 Segurança

### Validação de Webhook

```javascript
// 1. Verifica headers
const signature = req.get('X-Signature');
const timestamp = req.get('X-Timestamp');

// 2. Valida timestamp (máximo 5 minutos)
const currentTime = Math.floor(Date.now() / 1000);
const incomingTime = parseInt(timestamp, 10);
if (Math.abs(currentTime - incomingTime) > 300) {
  return res.status(401).json({ error: 'Stale timestamp' });
}

// 3. Valida assinatura HMAC
const hmac = crypto.createHmac('sha256', WEBHOOK_SECRET);
const expectedSignature = hmac.update(rawBody).digest('hex');

if (!crypto.timingSafeEqual(expectedBuffer, providedBuffer)) {
  return res.status(401).json({ error: 'Invalid signature' });
}
```

### Configuração no Firestore

```javascript
// AppInfo/didio
{
  "api_key": "sua-api-key",
  "app_id": "seu-app-id",
  "webhook_secret": "seu-webhook-secret-key",
  "callback_url": "https://partiu.app/verification/callback"
}
```

## 📊 Estrutura de Dados

### DiditWebhooks (Histórico)

```
DiditWebhooks/{auto-id}/
  ├── session_id: string
  ├── status: "Approved" | "Declined" | "In Review" | "In Progress"
  ├── webhook_type: "status.updated" | "data.updated"
  ├── vendor_data: string (userId)
  ├── workflow_id: string
  ├── metadata: Map
  ├── decision: {
  │     session_id: string
  │     status: string
  │     id_verification: {
  │         status: "Approved"
  │         document_type: "Identity Card"
  │         document_number: "ABC123"
  │         full_name: "João Silva"
  │         date_of_birth: "1990-01-01"
  │         age: 34
  │         gender: "M"
  │         nationality: "BRA"
  │         portrait_image: "https://..."
  │         ...
  │     }
  │     reviews: [...]
  │   }
  ├── created_at: number
  ├── timestamp: number
  ├── received_at: Timestamp
  └── processed: boolean
```

### FaceVerifications (Auto-salvo em Aprovação)

```
FaceVerifications/{userId}/
  ├── userId: string
  ├── facialId: string (session_id)
  ├── verifiedAt: Timestamp
  ├── status: "verified"
  ├── gender: "M" | "F"
  ├── age: number
  └── details: {
        verification_type: "didit"
        verification_date: ISO8601
        document_type: "Identity Card"
        document_number: "ABC123"
        full_name: "João Silva"
        first_name: "João"
        last_name: "Silva"
        date_of_birth: "1990-01-01"
        nationality: "BRA"
        issuing_state: "Brazil"
        portrait_image: "https://..."
        session_id: string
        session_url: string
      }
```

### Users (Auto-atualizado)

```
Users/{userId}/
  ├── user_is_verified: true
  ├── verified_at: Timestamp
  ├── facial_id: string (session_id)
  └── verification_type: "didit"
```

## 🚀 Deploy e Configuração

### 1. Deploy da Cloud Function

```bash
cd functions
npm install firebase-functions firebase-admin crypto
firebase deploy --only functions:diditWebhook,functions:reprocessDiditWebhook
```

### 2. Configurar no Dashboard Didit

1. Acesse: https://dashboard.didit.me/
2. Vá em **Verification Settings**
3. Adicione Webhook URL:
   ```
   https://us-central1-partiu-479902.cloudfunctions.net/diditWebhook
   ```
4. Copie o **Webhook Secret Key**
5. Adicione ao Firestore em `AppInfo/didio`:
   ```javascript
   {
     "webhook_secret": "cole-aqui-o-secret-key"
   }
   ```

### 3. Whitelist Cloudflare (se usar)

Se usa Cloudflare:
1. Vá em **Security → WAF → Tools → IP Access Rules**
2. Adicione IP: `18.203.201.92`
3. Action: **Allow**

## 📝 Tipos de Eventos

### status.updated

Enviado quando o status muda:
- `Not Started` → `In Progress`
- `In Progress` → `In Review`
- `In Review` → `Approved` ✅
- `In Review` → `Declined` ❌

### data.updated

Enviado quando dados KYC/POA são atualizados manualmente por um revisor.

## 🔄 Fluxo Completo

```
1. Usuário completa verificação no Didit
   ↓
2. Didit processa e aprova
   ↓
3. Didit envia webhook para Cloud Function
   ↓
4. Function valida assinatura HMAC
   ↓
5. Function valida timestamp
   ↓
6. Function salva webhook em DiditWebhooks
   ↓
7. Function atualiza DiditSessions
   ↓
8. Se Approved: Function salva em FaceVerifications
   ↓
9. Function atualiza Users.user_is_verified = true
   ↓
10. App detecta mudança via Stream
   ↓
11. UI atualiza automaticamente
```

## 🛠️ Funções Disponíveis

### diditWebhook (HTTP)

Endpoint principal para receber webhooks:

```
POST https://us-central1-partiu-479902.cloudfunctions.net/diditWebhook
Headers:
  X-Signature: {hmac-sha256-signature}
  X-Timestamp: {unix-timestamp}
Body: {webhook-json}
```

### reprocessDiditWebhook (Callable)

Reprocessa um webhook manualmente:

```dart
// No app
final result = await FirebaseFunctions.instance
    .httpsCallable('reprocessDiditWebhook')
    .call({'session_id': 'xxx-xxx-xxx'});
```

Ou via curl:
```bash
curl -X POST https://us-central1-partiu-479902.cloudfunctions.net/reprocessDiditWebhook \
  -H "Content-Type: application/json" \
  -d '{"data": {"session_id": "xxx-xxx-xxx"}}'
```

## 🔍 Monitoramento

### Logs da Cloud Function

```bash
firebase functions:log --only diditWebhook
```

### Consultar Webhooks no Firestore

```javascript
// Todos os webhooks de uma sessão
db.collection('DiditWebhooks')
  .where('session_id', '==', 'xxx')
  .orderBy('timestamp', 'desc')
  .get()

// Webhooks não processados
db.collection('DiditWebhooks')
  .where('processed', '==', false)
  .get()

// Verificações aprovadas
db.collection('DiditWebhooks')
  .where('status', '==', 'Approved')
  .get()
```

## 🧪 Testes

### Simular Webhook Localmente

```javascript
// test_webhook.js
const crypto = require('crypto');

const webhookData = {
  session_id: "test-session-id",
  status: "Approved",
  webhook_type: "status.updated",
  created_at: Math.floor(Date.now() / 1000),
  timestamp: Math.floor(Date.now() / 1000),
  vendor_data: "user-id-here",
  decision: {
    session_id: "test-session-id",
    status: "Approved",
    id_verification: {
      status: "Approved",
      document_type: "Identity Card",
      full_name: "Test User",
      age: 30,
      gender: "M"
    }
  }
};

const rawBody = JSON.stringify(webhookData);
const secret = "your-webhook-secret";
const hmac = crypto.createHmac('sha256', secret);
const signature = hmac.update(rawBody).digest('hex');

console.log('Signature:', signature);
console.log('Timestamp:', webhookData.timestamp);
console.log('Body:', rawBody);
```

### Testar com cURL

```bash
curl -X POST http://localhost:5001/partiu-479902/us-central1/diditWebhook \
  -H "Content-Type: application/json" \
  -H "X-Signature: {signature-gerada}" \
  -H "X-Timestamp: {timestamp}" \
  -d '{webhook-json}'
```

## ⚠️ Tratamento de Erros

### Retry Policy do Didit

Se a função retornar 5xx ou 404:
- **1ª tentativa:** ~1 minuto depois
- **2ª tentativa:** ~4 minutos depois
- **Desiste** após 2 falhas

### Erros Comuns

| Erro | Causa | Solução |
|------|-------|---------|
| 401 - Invalid signature | Secret key errado | Verificar `webhook_secret` no Firestore |
| 401 - Stale timestamp | Webhook > 5 min | Normal em retry, ignorar |
| 500 - Config not found | AppInfo/didio ausente | Criar documento |
| Webhook não chega | Cloudflare bloqueando | Whitelist IP 18.203.201.92 |

## 📈 Métricas

Monitorar:
- Taxa de webhooks recebidos
- Taxa de aprovação/rejeição
- Tempo de processamento
- Webhooks não processados
- Erros de assinatura

```javascript
// Consulta de métricas
db.collection('DiditWebhooks')
  .where('received_at', '>=', last7Days)
  .get()
  .then(snapshot => {
    const total = snapshot.size;
    const approved = snapshot.docs.filter(d => d.data().status === 'Approved').length;
    const declined = snapshot.docs.filter(d => d.data().status === 'Declined').length;
    
    console.log('Total:', total);
    console.log('Aprovados:', approved, `(${(approved/total*100).toFixed(1)}%)`);
    console.log('Recusados:', declined, `(${(declined/total*100).toFixed(1)}%)`);
  });
```

## 🎓 Exemplo de Uso no App

```dart
// Observar webhooks de uma sessão
Stream<List<DiditWebhook>> watchSessionWebhooks(String sessionId) {
  return FirebaseFirestore.instance
      .collection('DiditWebhooks')
      .where('session_id', isEqualTo: sessionId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => DiditWebhook.fromJson(doc.data()))
          .toList());
}

// Usar na UI
watchSessionWebhooks(sessionId).listen((webhooks) {
  final latest = webhooks.firstOrNull;
  if (latest?.isApproved ?? false) {
    showSuccess('Verificação aprovada!');
  }
});
```

## 📚 Referências

- [Didit Webhooks Docs](https://docs.didit.me/webhooks)
- [HMAC Signature Validation](https://en.wikipedia.org/wiki/HMAC)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)

---

**Implementação completa! Webhook seguro e automatizado! 🎉**
