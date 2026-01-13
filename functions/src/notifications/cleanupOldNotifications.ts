import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const BATCH_SIZE = 500;
const RETENTION_DAYS = 10;

/**
 * Cloud Function: Remove notificações antigas da coleção raiz `Notifications`.
 *
 * Política:
 * - Deleta docs onde `timestamp` < (agora - 10 dias)
 * - Paginação por `timestamp` para não estourar memória
 *
 * Observações:
 * - Requer que `timestamp` exista como Firestore Timestamp.
 * - Se houver docs sem `timestamp`, eles não entram na query.
 */
export const cleanupOldNotifications = functions
  .region("us-central1")
  .runWith({timeoutSeconds: 540, memory: "512MB"})
  // Diário às 03:10 (BRT) para evitar concorrência com outros jobs.
  .pubsub.schedule("10 3 * * *")
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    const startMs = Date.now();
    const cutoffDate = new Date(
      Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000
    );
    const cutoff = admin.firestore.Timestamp.fromDate(cutoffDate);

    console.log(
      `🧹 [cleanupOldNotifications] Iniciando limpeza: timestamp < ${
        cutoffDate.toISOString()
      } (retenção ${RETENTION_DAYS}d)`
    );

    let totalDeleted = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;

    // Guard para evitar timeout (deixa margem dentro de 540s)
    const maxRuntimeMs = 8 * 60 * 1000;

    while (Date.now() - startMs < maxRuntimeMs) {
      let query = db
        .collection("Notifications")
        .where("timestamp", "<", cutoff)
        .orderBy("timestamp", "asc")
        .limit(BATCH_SIZE);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();

      if (snapshot.empty) {
        break;
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];

      const batch = db.batch();
      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
      }

      await batch.commit();

      totalDeleted += snapshot.size;
      console.log(
        `🗑️ [cleanupOldNotifications] Batch deletado: ${snapshot.size} ` +
          `(total: ${totalDeleted})`
      );

      if (snapshot.size < BATCH_SIZE) {
        break;
      }
    }

    const durationMs = Date.now() - startMs;
    console.log(
      `✅ [cleanupOldNotifications] Concluído: ${totalDeleted} deletadas ` +
        `em ${Math.round(durationMs / 1000)}s`
    );

    return {
      success: true,
      retentionDays: RETENTION_DAYS,
      cutoffIso: cutoffDate.toISOString(),
      deleted: totalDeleted,
      durationMs,
    };
  });
