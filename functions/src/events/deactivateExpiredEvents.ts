import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Constantes de configuração
const BATCH_SIZE = 500;
const MAX_CONCURRENT_NOTIFICATION_DELETES = 10;

/**
 * Desativa eventos expirados automaticamente
 *
 * Trigger: Scheduled function (executa todos os dias à meia-noite)
 * Busca eventos ativos cuja data do evento (schedule.date) já passou
 *
 * Comportamento:
 * - Executa à 00:00 (meia-noite) horário de São Paulo
 * - Busca eventos com isActive=true (paginado, sem limite)
 * - Verifica se schedule.date < início do dia atual (00:00 de hoje)
 * - Atualiza isActive=false
 * - Deleta todas as notificações relacionadas ao evento (em paralelo)
 * - O Firestore emite automaticamente stream que remove markers no mapa
 *
 * Requisitos:
 * - Índice composto no Firestore: events(isActive ASC, schedule.date ASC)
 *
 * Exemplo:
 * - Função roda: 25/12/2025 00:00
 * - Evento com schedule.date: 20/12/2025 14:00 ou 24/12/2025 23:59
 * - Resultado: isActive = false (eventos anteriores a 25/12 desativados)
 */
export const deactivateExpiredEvents = functions
  .region("us-central1")
  .runWith({timeoutSeconds: 540, memory: "512MB"})
  .pubsub
  .schedule("0 0 * * *") // Cron: todos os dias à meia-noite
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const todayStart = new Date(now.toDate());

    // Definir início do dia atual (00:00:00)
    todayStart.setHours(0, 0, 0, 0);

    const todayStartTimestamp = admin.firestore.Timestamp
      .fromDate(todayStart);

    console.log(
      "🗓️ [DeactivateEvents] Verificando eventos expirados..."
    );
    console.log(
      `📅 [DeactivateEvents] Data/hora atual: ${
        now.toDate().toISOString()}`
    );
    console.log(
      `📅 [DeactivateEvents] Início de hoje: ${
        todayStartTimestamp.toDate().toISOString()}`
    );
    console.log(
      "📅 [DeactivateEvents] Desativando eventos com " +
      `schedule.date < ${todayStartTimestamp.toDate().toISOString()}`
    );

    try {
      // Contadores globais
      let totalBatchCount = 0;
      let totalBatches = 0;
      let totalNotificationsDeleted = 0;

      // ✅ Loop paginado para processar TODOS os eventos expirados
      let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;

      do {
        // Construir query paginada
        // Busca eventos cuja data já passou (schedule.date < início de hoje)
        let query = admin.firestore()
          .collection("events")
          .where("isActive", "==", true)
          .where("schedule.date", "<", todayStartTimestamp)
          .orderBy("schedule.date", "asc") // Necessário para paginação
          .limit(BATCH_SIZE);

        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const eventsSnapshot = await query.get();

        if (eventsSnapshot.empty) {
          if (totalBatchCount === 0) {
            console.log(
              "✅ [DeactivateEvents] Nenhum evento expirado para desativar"
            );
          }
          break;
        }

        // Atualizar cursor para próxima página
        lastDoc = eventsSnapshot.docs[eventsSnapshot.docs.length - 1];

        console.log(
          `📅 [DeactivateEvents] Página ${totalBatches + 1}: ` +
          `${eventsSnapshot.size} eventos encontrados`
        );

        // ✅ IDs desta página apenas (não acumula em memória)
        const pageEventIds: string[] = [];

        // Processar em batch para performance
        const batch = admin.firestore().batch();
        let batchCount = 0;

        for (const doc of eventsSnapshot.docs) {
          const data = doc.data();
          const eventDate = data.schedule?.date?.toDate?.();

          console.log(`🔍 [DeactivateEvents] Evento ${doc.id}:`);
          console.log(
            `   - Título: ${data.title || data.activityText || "Sem título"}`
          );
          console.log(
            `   - Data do evento: ${
              eventDate?.toISOString() || "Sem data"}`
          );

          // Pular eventos já deletados
          if (data.deleted === true) {
            console.log("   ❌ Pulando - evento deletado");
            continue;
          }

          // Coletar ID do evento para deletar notificações desta página
          pageEventIds.push(doc.id);

          // Adicionar ao batch
          batch.update(doc.ref, {
            isActive: false,
            status: "inactive",
            deactivatedAt: now,
            deactivatedReason: "expired",
          });

          batchCount++;
          console.log("   ✅ Marcado para desativação");
        }

        // Commit batch desta página
        if (batchCount > 0) {
          await batch.commit();
          totalBatchCount += batchCount;
          totalBatches++;
          console.log(
            `💾 [DeactivateEvents] Batch ${totalBatches} commitado ` +
            `(${batchCount} eventos)`
          );
        }

        // ✅ Deletar notificações DESTA PÁGINA imediatamente
        // Evita acúmulo de memória em cenários de escala extrema
        if (pageEventIds.length > 0) {
          console.log(
            "🗑️ [DeactivateEvents] Deletando notificações de " +
            `${pageEventIds.length} eventos da página ${totalBatches}...`
          );

          const pageNotificationsDeleted = await deleteNotificationsInParallel(
            pageEventIds,
            MAX_CONCURRENT_NOTIFICATION_DELETES
          );

          totalNotificationsDeleted += pageNotificationsDeleted;
          console.log(
            `   ✅ ${pageNotificationsDeleted} notificações deletadas`
          );
        }

        // Continuar enquanto houver mais páginas
      } while (lastDoc !== null);

      console.log(
        `✅ [DeactivateEvents] ${totalBatchCount} eventos desativados ` +
        `em ${totalBatches} batch(es)`
      );
      console.log(
        `✅ [DeactivateEvents] ${totalNotificationsDeleted} ` +
        "notificações deletadas no total"
      );

      console.log(
        "📡 [DeactivateEvents] Firestore streams notificarão " +
        "clientes automaticamente"
      );

      return {
        processed: totalBatchCount,
        batches: totalBatches,
        notificationsDeleted: totalNotificationsDeleted,
        timestamp: now.toDate().toISOString(),
      };
    } catch (error) {
      console.error(
        "❌ [DeactivateEvents] Erro ao desativar eventos:",
        error
      );
      throw error;
    }
  });

/**
 * Deleta notificações de múltiplos eventos em paralelo
 * com controle de concorrência para evitar timeout
 * @param {string[]} eventIds - IDs dos eventos
 * @param {number} concurrency - Número máximo de operações simultâneas
 * @return {Promise<number>} - Total de notificações deletadas
 */
async function deleteNotificationsInParallel(
  eventIds: string[],
  concurrency: number
): Promise<number> {
  let totalDeleted = 0;

  // Processar em chunks de 'concurrency' eventos por vez
  for (let i = 0; i < eventIds.length; i += concurrency) {
    const chunk = eventIds.slice(i, i + concurrency);

    const results = await Promise.all(
      chunk.map((eventId) => deleteEventNotifications(eventId))
    );

    totalDeleted += results.reduce((sum, count) => sum + count, 0);

    console.log(
      `   📊 Progresso: ${Math.min(i + concurrency, eventIds.length)}/` +
      `${eventIds.length} eventos processados`
    );
  }

  return totalDeleted;
}

/**
 * Deleta todas as notificações relacionadas a um evento específico
 * Busca por eventId em n_params.eventId e no campo eventId direto
 * @param {string} eventId - ID do evento
 * @return {Promise<number>} - Número de notificações deletadas
 */
async function deleteEventNotifications(eventId: string): Promise<number> {
  const db = admin.firestore();
  let totalDeleted = 0;

  try {
    // Buscar notificações com eventId no campo direto
    const directQuery = await db
      .collection("Notifications")
      .where("eventId", "==", eventId)
      .get();

    // Buscar notificações com eventId em n_params
    const paramsQuery = await db
      .collection("Notifications")
      .where("n_params.eventId", "==", eventId)
      .get();

    // Combinar resultados únicos (evitar duplicatas)
    const docsToDelete = new Map<string, FirebaseFirestore.DocumentReference>();

    directQuery.docs.forEach((doc) => {
      docsToDelete.set(doc.id, doc.ref);
    });

    paramsQuery.docs.forEach((doc) => {
      docsToDelete.set(doc.id, doc.ref);
    });

    if (docsToDelete.size === 0) {
      return 0;
    }

    // Deletar em batch (máximo 500 por batch)
    const refs = Array.from(docsToDelete.values());

    for (let i = 0; i < refs.length; i += BATCH_SIZE) {
      const batchRefs = refs.slice(i, i + BATCH_SIZE);
      const batch = db.batch();

      batchRefs.forEach((ref) => batch.delete(ref));
      await batch.commit();
    }

    totalDeleted = refs.length;
  } catch (error) {
    console.error(
      `   ❌ Erro ao deletar notificações do evento ${eventId}:`,
      error
    );
  }

  return totalDeleted;
}
