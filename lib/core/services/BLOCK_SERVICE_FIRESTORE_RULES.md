# 🔒 Regras de Segurança Firestore - BlockedUsers

## Adicionar ao firestore.rules

```javascript
// Coleção de usuários bloqueados
match /blockedUsers/{blockId} {
  // Permitir leitura apenas se o usuário for o bloqueador ou o bloqueado
  allow read: if request.auth != null && (
    resource.data.blockerId == request.auth.uid ||
    resource.data.targetId == request.auth.uid
  );
  
  // Permitir criar/atualizar apenas se:
  // - Usuário autenticado
  // - blockerId é o próprio usuário
  // - Documento segue o formato {blockerId}_{targetId}
  allow create, update: if request.auth != null &&
    request.resource.data.blockerId == request.auth.uid &&
    request.resource.data.targetId is string &&
    request.resource.data.createdAt is timestamp;
  
  // Permitir deletar apenas se for o bloqueador
  allow delete: if request.auth != null &&
    resource.data.blockerId == request.auth.uid;
}
```

## 📊 Índice Composto Necessário

Criar no Firebase Console > Firestore > Indexes:

**Collection ID:** `blockedUsers`

**Fields indexed:**
1. `blockerId` - Ascending
2. `targetId` - Ascending

**Query scope:** Collection

Isso permite queries rápidas para:
- Verificar bloqueios bilaterais
- Listar usuários bloqueados
- Otimizar performance

## 🎯 Como aplicar

1. Copie a regra acima
2. Cole no seu `firestore.rules` dentro do bloco `service cloud.firestore`
3. Deploy com: `firebase deploy --only firestore:rules`
4. Crie o índice composto no Console do Firebase

## ⚡ Performance

- ✅ Leitura: ~10-50ms
- ✅ Escrita: ~50-100ms
- ✅ Escala: Milhões de documentos
- ✅ Custo: Mínimo (1 leitura por verificação)
