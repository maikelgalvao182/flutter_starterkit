# 🔧 Didit Troubleshooting Guide

## ❌ Erro: "Invalid workflow_id"

### Causa
O campo `app_id` no Firestore não contém um workflow_id válido do Didit.

### Solução

1. **Acesse o Dashboard Didit:**
   - URL: https://dashboard.didit.me
   - Faça login com suas credenciais

2. **Encontre seu Workflow ID:**
   - Vá em **Workflows** no menu lateral
   - Clique no workflow que deseja usar (ex: "ID Verification")
   - Copie o **Workflow ID** (formato UUID: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

3. **Configure no Firestore:**
   ```javascript
   // Caminho: AppInfo/didio
   {
     "api_key": "sua-api-key-aqui",
     "app_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", // ← Cole o Workflow ID aqui
     "callback_url": "https://partiu.app/verification/callback",
     "webhook_secret": "seu-webhook-secret"
   }
   ```

4. **Limpe o cache e teste novamente:**
   - O app cacheia as configurações
   - Reinicie o app ou force reload

### Validação

O `app_id` deve ser um UUID válido no formato:
```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Exemplo válido:
```
f47ac10b-58cc-4372-a567-0e02b2c3d479
```

---

## ❌ Erro: "Configuration not found"

### Causa
O documento `AppInfo/didio` não existe no Firestore.

### Solução

1. Acesse o Firebase Console:
   - https://console.firebase.google.com
   - Selecione o projeto: `partiu-479902`

2. Vá em **Firestore Database**

3. Crie a estrutura:
   ```
   AppInfo (collection)
   └── didio (document)
       ├── api_key: "sua-api-key"
       ├── app_id: "seu-workflow-id-uuid"
       ├── callback_url: "https://partiu.app/verification/callback"
       └── webhook_secret: "seu-secret"
   ```

---

## ❌ Erro: "Webhook secret not configured"

### Causa
O campo `webhook_secret` está ausente ou vazio no Firestore.

### Solução

1. Acesse **AppInfo/didio** no Firestore

2. Adicione o campo `webhook_secret`:
   ```javascript
   {
     "api_key": "...",
     "app_id": "...",
     "webhook_secret": "uma-chave-secreta-forte-aqui"
   }
   ```

3. Configure o mesmo secret no Dashboard Didit:
   - Settings → Webhooks
   - Adicione o mesmo valor em "Secret"

---

## ❌ Erro: "Invalid signature"

### Causa
A assinatura HMAC do webhook não corresponde.

### Possíveis Causas

1. **Secret diferente:**
   - Firestore tem um valor
   - Dashboard Didit tem outro valor
   - **Solução:** Use o mesmo `webhook_secret` em ambos

2. **Cloudflare modificando payload:**
   - Cloudflare pode alterar o body do request
   - **Solução:** Whitelist o IP do Didit: `18.203.201.92`

3. **Timestamp expirado:**
   - Webhook com mais de 5 minutos
   - **Solução:** Verifique relógio do servidor

---

## ❌ Webhook não chega na Cloud Function

### Diagnóstico

1. **Verifique a URL configurada no Didit:**
   ```
   https://us-central1-partiu-479902.cloudfunctions.net/diditWebhook
   ```

2. **Teste manualmente:**
   ```bash
   curl -X POST https://us-central1-partiu-479902.cloudfunctions.net/diditWebhook \
     -H "Content-Type: application/json" \
     -d '{"test": true}'
   ```

3. **Verifique logs da função:**
   ```bash
   firebase functions:log --only diditWebhook
   ```

### Soluções

1. **Cloudflare bloqueando:**
   - Whitelist IP: `18.203.201.92`
   - Ou desabilite proteções para essa rota

2. **Função não deployada:**
   ```bash
   firebase deploy --only functions:diditWebhook
   ```

3. **Permissões incorretas:**
   - A função deve ter permissão `allUsers`
   - Verifique no Cloud Console

---

## 🔍 Como debugar

### 1. Logs do App (Flutter)

```dart
// Todos os logs do Didit usam o tag [DiditVerificationService]
AppLogger.info('...', tag: 'DiditVerificationService');
```

### 2. Logs da Cloud Function

```bash
# Ver logs em tempo real
firebase functions:log --only diditWebhook

# Ver últimos 100 logs
firebase functions:log --only diditWebhook --lines 100
```

### 3. Firestore

Verifique as collections:

```
DiditSessions/{sessionId}
├── sessionId
├── userId
├── status (pending → processing → completed/failed)
├── url
├── workflowId
├── createdAt
└── vendorData

DiditWebhooks/{auto-id}
├── sessionId
├── webhookType
├── decision { status, reasons[], createdAt }
├── idVerification { ... }
└── receivedAt

FaceVerifications/{userId}
├── facialId (session_id do Didit)
├── verificationType: "didit"
├── verifiedAt
└── userInfo { ... }
```

---

## ✅ Checklist de Configuração

- [ ] Dashboard Didit configurado
  - [ ] Workflow ID copiado
  - [ ] API Key gerada
  - [ ] Webhook URL configurada
  - [ ] Webhook Secret configurado

- [ ] Firestore configurado
  - [ ] Documento `AppInfo/didio` existe
  - [ ] Campo `api_key` preenchido
  - [ ] Campo `app_id` preenchido (Workflow ID UUID)
  - [ ] Campo `webhook_secret` preenchido
  - [ ] Campo `callback_url` preenchido (opcional)

- [ ] Cloud Function deployada
  - [ ] `diditWebhook` deployada
  - [ ] `reprocessDiditWebhook` deployada
  - [ ] Logs sem erros

- [ ] Cloudflare (se aplicável)
  - [ ] IP `18.203.201.92` whitelisted
  - [ ] Ou proteções desabilitadas para rota `/diditWebhook`

- [ ] App Flutter
  - [ ] Dependências instaladas (`flutter pub get`)
  - [ ] Permissões configuradas (camera, microphone)
  - [ ] App rodando em device físico (não emulador)

---

## 📞 Suporte

Se o problema persistir:

1. **Verifique a documentação oficial:**
   - https://docs.didit.me

2. **Colete informações:**
   - Logs do Flutter
   - Logs da Cloud Function
   - Screenshot do erro
   - Configuração do Firestore (sem expor secrets)

3. **Contate o suporte do Didit:**
   - support@didit.me
   - Dashboard → Support

---

## 🚀 Teste Rápido

Após configurar tudo, teste assim:

```bash
# 1. Limpe o cache do app
flutter clean

# 2. Reinstale dependências
flutter pub get

# 3. Rode no device físico
flutter run --release

# 4. Navegue até a verificação
# 5. Observe os logs
```

Se aparecer:
```
✅ Configurações do Didit carregadas com sucesso
✅ Criando sessão de verificação no Didit...
✅ Sessão criada com sucesso: xxxxx
```

Significa que está funcionando! 🎉
