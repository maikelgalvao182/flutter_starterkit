# Auditoria de Memória — Cloud Function `deleteChatMessage`

Data: 2026-01-11  
Escopo: [functions/src/chatMessageDeletion.ts](functions/src/chatMessageDeletion.ts)

## Resumo executivo

- **Não encontrei vazamentos de memória clássicos** (estado global crescente, listeners/intervals persistentes, handles abertos) na implementação atual.
- O principal risco prático aqui é **pressão de memória por leitura de lotes do Firestore** (até 200 documentos por query, com paginação de até 5 páginas) e por **fan-out** de updates para muitos participantes.
- Em Cloud Functions (Node.js), “vazamento” geralmente aparece quando o processo fica “warm” e a memória não volta ao baseline entre invocações. Neste código, o que pode ocorrer é **pico de memória por invocação**, não crescimento indefinido.

## Como avaliei (critérios)

Procurei sinais típicos de vazamento/retensão entre invocações:

- Variáveis/coleções em **escopo de módulo** que acumulam itens.
- `setInterval`, `setTimeout` recorrente, event listeners (`on(...)`) sem remoção.
- Promises pendentes por falta de `await`.
- Logs/objetos enormes retidos em closures ou retornados.

Também identifiquei pontos de **alto consumo transitório**:

- Queries com `limit(200)` e paginação.
- Arrays de snapshots (`QuerySnapshot.docs`) mantidos em memória.
- Loops que criam batches repetidamente.

## Achados

### 1) Leitura de 200 mensagens + retenção de array (Evento)

Trecho: [functions/src/chatMessageDeletion.ts](functions/src/chatMessageDeletion.ts#L323-L356)

- A função carrega **até 200 mensagens** (`limit(200)`) e armazena `latestSnap.docs` em `recentMessages`.
- Isso é usado para:
  - encontrar a última mensagem “efetiva” (não deletada)
  - calcular um replacement do preview

**Risco (memória):** baixo a médio. 200 docs normalmente é ok, mas o tamanho real depende do payload de cada mensagem (texto, anexos serializados, metadados etc.).

**Observação:** isso não é vazamento (não persiste após a invocação), mas pode causar **picos** e aumentar chance de OOM se combinado com mensagens grandes.

**Recomendação:**
- Se houver como garantir que mensagens novas sempre tenham `is_deleted: false`, priorizar query direta e reduzir o lote “recent” (ex.: 50/100) e só paginar se necessário.

### 2) Paginação fallback (Evento) pode ler até ~1000 docs

Trecho: [functions/src/chatMessageDeletion.ts](functions/src/chatMessageDeletion.ts#L382-L418)

- No pior caso, o fallback pagina até 5 vezes com `limit(200)`.
- Isso pode materializar até ~1000 documentos ao longo da execução.

**Risco (memória):** médio (pico por invocação). Em especial se as mensagens tiverem campos grandes.

**Recomendação:**
- Manter o cap (já existe) e considerar reduzir `attempt < 5` ou `limit(200)` se a base de mensagens crescer.
- Preferir resolver o preview com um “source of truth” (ex.: manter `lastMessageId`/`lastMessageAt` consistente no doc do chat), evitando varredura.

### 3) Fan-out de updates para muitos participantes (Evento)

Trecho: [functions/src/chatMessageDeletion.ts](functions/src/chatMessageDeletion.ts#L472-L514)

- Atualiza a conversa em `Connections/{participantId}/Conversations/event_{eventId}` para cada participante.
- O chunking em `CHUNK_SIZE = 400` é bom para limite de batch, mas:
  - **Se `participantIds` for muito grande**, a invocação fica longa e consome memória/CPU mais tempo.

**Risco (memória):** baixo a médio (principalmente tempo de execução e custo). Ainda assim é consumo transitório.

**Recomendação:**
- Se eventos puderem ter milhares de participantes, considerar arquitetura de atualização assíncrona (fila/trigger) para distribuir carga.

### 4) Recalcular preview (1:1) também lê lotes de 200 + paginação

Trecho: [functions/src/chatMessageDeletion.ts](functions/src/chatMessageDeletion.ts#L735-L812)

- A função `readReplacement()` executa:
  - `limit(200)`
  - fallback com `.where('is_deleted', '==', false).orderBy('timestamp')...`
  - paginação limitada de até 5 páginas

**Risco (memória):** baixo a médio (pico por invocação), mesmo padrão do evento.

**Recomendação:**
- Mesmo ajuste sugerido acima: reduzir o lote e minimizar paginação.

### 5) Pontos onde NÃO há sinais de vazamento clássico

- Inicialização do Admin SDK em escopo global é estável: [functions/src/chatMessageDeletion.ts](functions/src/chatMessageDeletion.ts#L1-L9)
- Não há timers, listeners ou caches globais crescendo.
- Uso de `await` é consistente; não observei “promises soltas” deixando trabalho pendente.

## Conclusão

- **Vazamento de memória persistente:** não identificado neste arquivo.
- **Maior risco real:** picos de memória por leitura de lotes do Firestore (200/1000 docs) e tempo de invocação em cenários grandes.

## Ações recomendadas (prioridade)

1) **Reduzir pressão de memória nas varreduras**
   - Diminuir `limit(200)` onde possível, e/ou reduzir `attempt < 5`.
2) **Evoluir o “contrato” de dados de mensagens**
   - Garantir que mensagens novas sempre tenham `is_deleted: false` para permitir query direta sem varredura.
3) **Observabilidade**
   - Monitorar métricas de memória (Cloud Monitoring) e correlacionar OOM com chats/eventos grandes.

## Sugestão de verificação em produção

- Acompanhar o consumo de memória por instância (Cloud Monitoring → Cloud Functions/Cloud Run metrics) e procurar padrão de “serra” (picos voltando ao baseline) versus “escada” (crescimento contínuo).
- Se houver suspeita de leak, habilitar logs amostrais de `process.memoryUsage().heapUsed` (com parcimônia) para confirmar tendência.
