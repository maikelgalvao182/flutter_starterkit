import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const BATCH_SIZE = 500;
const LOOKBACK_DAYS = 30;

/**
 * Cloud Function: Preenche `timestamp` em notificações antigas.
 *
 * Motivo:
 * - O app ordena e exibe notificações usando o campo `timestamp`.
 * - Algumas Cloud Functions antigas gravavam apenas `n_created_at`/`createdAt`.
 *
 * Estratégia:
 * - Varre um recorte recente usando `createdAt` e/ou `n_created_at`
 * - Preenche `timestamp = n_created_at || createdAt || serverTimestamp()`
 */
export const backfillMissingNotificationTimestamps = functions
  .region("us-central1")
  .runWith({timeoutSeconds: 540, memory: "512MB"})
  // A cada 2 horas, para ir drenando backlog sem custo alto.
  .pubsub.schedule("20 */2 * * *")
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    const startMs = Date.now();

    console.log("🧩 [backfillMissingNotificationTimestamps] Iniciando...");

    const cutoffDate = new Date(
      Date.now() - LOOKBACK_DAYS * 24 * 60 * 60 * 1000
    );
    const cutoff = admin.firestore.Timestamp.fromDate(cutoffDate);

    const notificationsRef = db.collection("Notifications");

    // Como Firestore não permite filtrar diretamente por "campo ausente",
    // varremos um recorte recente usando timestamps já existentes
    // (createdAt/n_created_at)
    // e preenchemos `timestamp` quando estiver faltando.
    const [byCreatedAt, byNCreatedAt] = await Promise.all([
      notificationsRef
        .where("createdAt", ">=", cutoff)
        .orderBy("createdAt", "desc")
        .limit(BATCH_SIZE)
        .get(),
      notificationsRef
        .where("n_created_at", ">=", cutoff)
        .orderBy("n_created_at", "desc")
        .limit(BATCH_SIZE)
        .get(),
    ]);

    const docsById = new Map<string, FirebaseFirestore.QueryDocumentSnapshot>();
    for (const doc of byCreatedAt.docs) {
      docsById.set(doc.id, doc);
    }
    for (const doc of byNCreatedAt.docs) {
      if (!docsById.has(doc.id)) {
        docsById.set(doc.id, doc);
      }
    }

    if (docsById.size === 0) {
      console.log(
        "✅ [backfillMissingNotificationTimestamps] " +
          "Nenhum doc recente encontrado"
      );
      return {
        success: true,
        updated: 0,
        lookedBackDays: LOOKBACK_DAYS,
      };
    }

    const batch = db.batch();
    let scanned = 0;
    let updated = 0;

    for (const doc of docsById.values()) {
      scanned++;
      const data = doc.data();

      // `timestamp` é o campo esperado pelo app.
      // Se não existir (ou for null), fazemos backfill.
      const currentTimestamp = data.timestamp;
      if (currentTimestamp != null) {
        continue;
      }

      const fromNCreatedAt = data.n_created_at;
      const fromCreatedAt = data.createdAt;

      const timestampValue =
        fromNCreatedAt ??
        fromCreatedAt ??
        admin.firestore.FieldValue.serverTimestamp();

      batch.update(doc.ref, {timestamp: timestampValue});
      updated++;
    }

    if (updated === 0) {
      console.log(
        "✅ [backfillMissingNotificationTimestamps] OK: 0 atualizadas " +
          `(scanned=${scanned})`
      );
      return {
        success: true,
        updated: 0,
        scanned,
        lookedBackDays: LOOKBACK_DAYS,
      };
    }

    await batch.commit();

    const durationMs = Date.now() - startMs;
    console.log(
      `✅ [backfillMissingNotificationTimestamps] Atualizadas: ${updated} ` +
        `em ${Math.round(durationMs / 1000)}s`
    );

    return {
      success: true,
      updated,
      scanned,
      lookedBackDays: LOOKBACK_DAYS,
      cutoffIso: cutoffDate.toISOString(),
      durationMs,
    };
  });
