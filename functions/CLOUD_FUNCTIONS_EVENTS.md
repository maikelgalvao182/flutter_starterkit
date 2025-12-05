# 🔥 Cloud Functions para Gerenciamento de Eventos

Este documento descreve as Cloud Functions criadas para gerenciar eventos de forma segura e confiável.

## 📋 Funções Disponíveis

### 1. `deleteEvent` - Deletar Evento

**Callable Function** que permite ao criador de um evento deletá-lo completamente.

#### Parâmetros
```typescript
{
  eventId: string  // ID do evento a ser deletado
}
```

#### Operações Realizadas
1. ✅ Valida que o usuário autenticado é o criador do evento
2. 🗑️ Remove documento na coleção `events`
3. 💬 Remove chat em `EventChats` e todas as mensagens
4. 📋 Remove todas as aplicações em `EventApplications`
5. 🔗 Remove conversas relacionadas de todos os participantes
6. 📦 Remove arquivos do Storage (async)

#### Retorno
```typescript
{
  success: boolean,
  message: string
}
```

#### Erros
- `unauthenticated`: Usuário não autenticado
- `invalid-argument`: eventId não fornecido
- `not-found`: Evento não encontrado
- `permission-denied`: Apenas o criador pode deletar o evento
- `internal`: Erro durante a execução

#### Exemplo de Uso (Flutter)
```dart
final functions = FirebaseFunctions.instance;
final result = await functions.httpsCallable('deleteEvent').call({
  'eventId': 'abc123',
});

if (result.data['success'] == true) {
  print('Evento deletado com sucesso!');
}
```

---

### 2. `removeUserApplication` - Remover Aplicação

**Callable Function** que permite a um usuário remover sua própria aplicação em um evento.

#### Parâmetros
```typescript
{
  eventId: string,
  userId?: string  // Opcional - se não fornecido, usa auth.uid
}
```

#### Operações Realizadas
1. ✅ Valida autenticação e permissões
2. 🗑️ Remove registro em `EventApplications`
3. 👥 Remove usuário do array `participants` em `EventChats`
4. 📉 Decrementa `participantCount` no chat
5. 🔗 Remove conversa do evento do usuário

#### Retorno
```typescript
{
  success: boolean,
  message: string
}
```

#### Erros
- `unauthenticated`: Usuário não autenticado
- `invalid-argument`: eventId não fornecido
- `not-found`: Aplicação não encontrada
- `permission-denied`: Sem permissão para remover outro usuário
- `internal`: Erro durante a execução

#### Exemplo de Uso (Flutter)
```dart
final functions = FirebaseFunctions.instance;
final result = await functions.httpsCallable('removeUserApplication').call({
  'eventId': 'abc123',
});

if (result.data['success'] == true) {
  print('Aplicação removida com sucesso!');
}
```

---

### 3. `removeParticipant` - Remover Participante (Criador)

**Callable Function** que permite ao criador do evento remover um participante específico.

#### Parâmetros
```typescript
{
  eventId: string,
  userId: string  // ID do participante a ser removido
}
```

#### Operações Realizadas
1. ✅ Valida que o usuário autenticado é o criador do evento
2. ✅ Valida que não está tentando remover a si mesmo
3. 🗑️ Remove aplicação do participante em `EventApplications`
4. 👥 Remove participante do array `participants` em `EventChats`
5. 📉 Decrementa `participantCount` no chat
6. 🔗 Remove conversa do evento do participante

#### Retorno
```typescript
{
  success: boolean,
  message: string
}
```

#### Erros
- `unauthenticated`: Usuário não autenticado
- `invalid-argument`: eventId ou userId não fornecido / tentando remover a si mesmo
- `not-found`: Evento ou aplicação não encontrada
- `permission-denied`: Apenas o criador pode remover participantes
- `internal`: Erro durante a execução

#### Exemplo de Uso (Flutter)
```dart
final functions = FirebaseFunctions.instance;
final result = await functions.httpsCallable('removeParticipant').call({
  'eventId': 'abc123',
  'userId': 'user456',
});

if (result.data['success'] == true) {
  print('Participante removido com sucesso!');
}
```

---

## 🚀 Deploy

### 1. Compilar TypeScript
```bash
cd functions
npm run build
```

### 2. Deploy das Funções
```bash
# Deploy todas as funções
firebase deploy --only functions

# Deploy apenas as funções de eventos
firebase deploy --only functions:deleteEvent,functions:removeUserApplication,functions:removeParticipant
```

### 3. Verificar Deploy
```bash
firebase functions:list
```

---

## 🔒 Regras de Segurança do Firestore

As Cloud Functions executam com privilégios administrativos, mas ainda é importante ter regras de segurança adequadas:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Events - apenas criador pode deletar via Cloud Function
    match /events/{eventId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                     (resource.data.createdBy == request.auth.uid || 
                      request.auth.token.admin == true);
      allow delete: if false; // Apenas via Cloud Function
    }
    
    // EventApplications - apenas via Cloud Function
    match /EventApplications/{applicationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if false; // Apenas via Cloud Function
    }
    
    // EventChats - apenas via Cloud Function
    match /EventChats/{chatId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if false; // Apenas via Cloud Function
      allow delete: if false; // Apenas via Cloud Function
      
      match /Messages/{messageId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
        allow delete: if false; // Apenas via Cloud Function
      }
    }
  }
}
```

---

## 🧪 Testes

### Teste Manual via Firebase Console

1. Acesse: https://console.firebase.google.com
2. Vá em **Functions** > Selecione a função
3. Clique em **Test the function**
4. Insira o payload JSON
5. Execute

### Teste via Flutter

```dart
try {
  final functions = FirebaseFunctions.instance;
  
  // Para desenvolvimento local (emulator)
  // functions.useFunctionsEmulator('localhost', 5001);
  
  final result = await functions.httpsCallable('deleteEvent').call({
    'eventId': 'test123',
  });
  
  print('Success: ${result.data['success']}');
  print('Message: ${result.data['message']}');
  
} on FirebaseFunctionsException catch (e) {
  print('Error Code: ${e.code}');
  print('Error Message: ${e.message}');
  print('Error Details: ${e.details}');
}
```

---

## 📊 Logs e Monitoramento

### Ver Logs no Console
```bash
firebase functions:log --only deleteEvent
firebase functions:log --only removeUserApplication
firebase functions:log --only removeParticipant
```

### Ver Logs em Tempo Real
```bash
firebase functions:log --only deleteEvent --since 10m --follow
```

### Cloud Console
1. Acesse: https://console.cloud.google.com
2. Vá em **Cloud Functions**
3. Selecione a função
4. Clique em **Logs**

---

## ⚡ Performance e Custos

### Batch Operations
As funções usam batch writes para minimizar operações de rede:
- Máximo de 500 operações por batch
- Múltiplos batches executados em paralelo

### Custos Estimados
- **deleteEvent**: ~500 reads + 500 writes + Storage deletes
- **removeUserApplication**: ~5 reads + 5 writes
- **removeParticipant**: ~5 reads + 5 writes

**Nota**: Storage deletes são executados de forma assíncrona e não contam para o timeout da função.

---

## 🔧 Troubleshooting

### Erro: "Firebase Functions has not been initialized"
```dart
// Certifique-se de inicializar o Firebase
await Firebase.initializeApp();
```

### Erro: "DEADLINE_EXCEEDED"
A função está demorando mais de 60 segundos. Considere:
- Aumentar o timeout da função
- Otimizar queries
- Processar storage deletes de forma async

### Erro: "PERMISSION_DENIED"
Verifique as regras de segurança do Firestore e que o usuário está autenticado.

---

## 📝 Changelog

### v1.0.0 (2025-12-04)
- ✨ Criação inicial das Cloud Functions
- 🔥 `deleteEvent`: Deleta evento completo
- 🚪 `removeUserApplication`: Remove aplicação do usuário
- 👤 `removeParticipant`: Remove participante (criador)
- 🔒 Validações de segurança server-side
- 📦 Limpeza automática de Storage
- 🎯 Operações atômicas com batch writes

---

## 🤝 Contribuindo

Ao modificar as Cloud Functions:
1. Teste localmente usando o emulator
2. Atualize esta documentação
3. Teste em ambiente de staging antes de produção
4. Monitore logs após deploy

---

## 📞 Suporte

Para problemas ou dúvidas:
- 📧 Email: suporte@partiu.com
- 📱 Slack: #backend-functions
- 📖 Wiki: https://wiki.partiu.com/cloud-functions
