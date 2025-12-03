# 🚀 Deploy das Cloud Functions - Chat de Eventos

## 📋 Pré-requisitos

- Node.js instalado
- Firebase CLI instalado: `npm install -g firebase-tools`
- Autenticado no Firebase: `firebase login`

## 🔧 Instalação das Dependências

```bash
cd functions
npm install
```

## 🏗️ Build das Functions

```bash
cd functions
npm run build
```

## 🚀 Deploy

### Deploy de todas as functions:
```bash
firebase deploy --only functions
```

### Deploy de uma function específica:
```bash
# Deploy apenas da onEventCreated
firebase deploy --only functions:onEventCreated

# Deploy apenas da onApplicationApproved
firebase deploy --only functions:onApplicationApproved
```

## 📊 Verificar Functions Ativas

```bash
firebase functions:list
```

## 📝 Functions Implementadas

### 1. `onEventCreated`
**Trigger:** Quando um documento é criado em `events/{eventId}`

**Ações:**
1. Cria application automática para o criador (`status: autoApproved`)
2. Cria `EventChats/{eventId}` com dados iniciais
3. Adiciona criador como primeiro participante em `EventChats/{eventId}/Participants/{creatorId}`

### 2. `onApplicationApproved`
**Trigger:** Quando um documento é atualizado em `EventApplications/{applicationId}`

**Ações (quando status muda para `approved` ou `autoApproved`):**
1. Adiciona usuário ao array `participantIds` do EventChat
2. Cria documento em `EventChats/{eventId}/Participants/{userId}`
3. Cria mensagem automática: "{Nome} entrou no grupo! 🎉"
4. Atualiza `lastMessage` do chat
5. Envia push notification para outros participantes

## 🧪 Testar Localmente

```bash
cd functions
npm run serve
```

Isso inicia o emulador local. Configure o Flutter para usar o emulador:

```dart
// No main.dart
if (kDebugMode) {
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

## 📊 Monitorar Logs

### Em produção:
```bash
firebase functions:log
```

### Logs de uma function específica:
```bash
firebase functions:log --only onEventCreated
```

### Logs em tempo real:
```bash
firebase functions:log --follow
```

## 🔒 Security Rules

Após o deploy das functions, faça deploy das Firestore Security Rules:

```bash
firebase deploy --only firestore:rules
```

## ⚠️ Troubleshooting

### Erro: "Deployment requires billing"
- Cloud Functions v1 requer billing ativo no projeto Firebase
- Ative o billing em: https://console.firebase.google.com/project/_/settings/billing

### Erro: "Cannot find module"
```bash
cd functions
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Function não está sendo executada
1. Verifique os logs: `firebase functions:log`
2. Confirme que o trigger está correto
3. Verifique se o documento está sendo criado/atualizado corretamente

## 📚 Documentação Adicional

- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Firestore Triggers](https://firebase.google.com/docs/functions/firestore-events)
- [Cloud Functions Pricing](https://firebase.google.com/pricing)

---

**Última atualização:** 3 de dezembro de 2025
