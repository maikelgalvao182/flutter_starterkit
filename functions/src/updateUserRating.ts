import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// PROBLEMA CRÍTICO CORRIGIDO: Inicializar Admin SDK
// Proteção contra dupla inicialização (caso index.ts já tenha inicializado)
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * ⭐ Cloud Function: Atualiza overallRating no documento Users
 *
 * Trigger: Quando uma Review é CRIADA
 * Ação: Recalcula média de todas as reviews do reviewee
 * e atualiza Users/{revieweeId}
 *
 * Benefícios:
 * - Single source of truth: Users.overallRating
 * - Performance: 1 read para obter rating (vs N reads)
 * - Sempre sincronizado automaticamente
 * - Evita loops com onCreate (vs onWrite)
 */

/**
 * Helper: Calcula média de criteria_ratings de uma review
 * @param {Record<string, number> | undefined} criteriaRatings
 * Map de critérios e notas
 * @return {number} Média dos valores ou 0 se vazio
 */
function calculateRatingFromCriteria(
  criteriaRatings: Record<string, number> | undefined
): number {
  if (!criteriaRatings || Object.keys(criteriaRatings).length === 0) {
    return 0;
  }

  const values = Object.values(criteriaRatings);

  // PROBLEMA 4 CORRIGIDO: filtrar valores inválidos
  // (NaN, negativos, fora do range)
  // Range válido: 1-5 (conforme modelo do app)
  const safeValues = values.filter(
    (v) => typeof v === "number" && !isNaN(v) && v >= 1 && v <= 5
  );

  if (safeValues.length === 0) {
    return 0;
  }

  const sum = safeValues.reduce((a, b) => a + b, 0);
  return sum / safeValues.length;
}

/**
 * Helper: Extrai rating de uma review (centralizado)
 * PROBLEMA 3 e 4 CORRIGIDO: lógica única para todas as funções
 * PROBLEMA 5 CORRIGIDO: priorizar overall_rating do app
 * (mais confiável)
 * @param {any} data - Dados da review
 * @return {number} Rating calculado ou 0
 */
function extractRatingFromReview(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  data: Record<string, any>
): number {
  // PRIORIDADE 1: usar overall_rating salvo pelo app
  // (já calculado e validado)
  if (data.overall_rating && typeof data.overall_rating === "number") {
    const rating = data.overall_rating;
    // Validar range (1-5)
    if (!isNaN(rating) && rating >= 1 && rating <= 5) {
      return rating;
    }
  }

  // FALLBACK: calcular de criteria_ratings
  // (reviews antigas ou inconsistentes)
  if (data.criteria_ratings) {
    return calculateRatingFromCriteria(data.criteria_ratings);
  }

  return 0;
}

export const updateUserRatingOnReviewCreate = functions.firestore
  .document("Reviews/{reviewId}")
  .onCreate(async (snapshot, context) => {
    // PROBLEMA 2 CORRIGIDO: db dentro da função (após initializeApp)
    const db = admin.firestore();

    try {
      const reviewId = context.params.reviewId;
      const reviewData = snapshot.data();

      // Validar revieweeId
      const revieweeId = reviewData?.reviewee_id;
      if (!revieweeId || typeof revieweeId !== "string") {
        console.warn(
          "⚠️ [updateUserRating] revieweeId inválido " +
          "para review " + reviewId
        );
        return;
      }

      console.log(
        "📊 [updateUserRating] Review criada, recalculando rating " +
        "para usuário: " + revieweeId
      );

      // Buscar todas as reviews do usuário
      const reviewsSnapshot = await db
        .collection("Reviews")
        .where("reviewee_id", "==", revieweeId)
        .get();

      if (reviewsSnapshot.empty) {
        console.log(
          "⚠️ [updateUserRating] Nenhuma review encontrada " +
          "para " + revieweeId + " (improvável após onCreate)"
        );

        // Usar set com merge para evitar erro se usuário não existe
        await db.collection("Users").doc(revieweeId).set({
          overallRating: 0,
          totalReviews: 0,
          lastRatingUpdate: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        return;
      }

      // Calcular média dos ratings
      let sumRatings = 0;
      let validRatingsCount = 0;

      for (const doc of reviewsSnapshot.docs) {
        const reviewData = doc.data();
        const rating = extractRatingFromReview(reviewData);

        // PROBLEMA 5 AJUSTADO: ignorar reviews com rating 0
        // (sem critérios preenchidos)
        if (rating > 0) {
          sumRatings += rating;
          validRatingsCount++;
        }
      }

      const overallRating = validRatingsCount > 0 ?
        Number((sumRatings / validRatingsCount).toFixed(2)) : 0;

      console.log(
        "✅ [updateUserRating] Rating calculado: " + overallRating + " " +
        "(" + validRatingsCount + " reviews válidas de " +
        reviewsSnapshot.size + " totais)"
      );

      // PROBLEMA 3 e 4 CORRIGIDO: usar set com merge e valor explícito 0
      await db.collection("Users").doc(revieweeId).set({
        overallRating: overallRating,
        totalReviews: validRatingsCount,
        lastRatingUpdate: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      console.log(
        "🎯 [updateUserRating] Rating atualizado com sucesso " +
        "para " + revieweeId
      );
    } catch (error) {
      console.error(
        "❌ [updateUserRating] Erro ao atualizar rating:",
        error
      );
      // Não lançar erro para não falhar a operação original
    }
  });

/**
 * ⭐ Cloud Function: Atualiza overallRating quando Review é DELETADA
 */
export const updateUserRatingOnReviewDelete = functions.firestore
  .document("Reviews/{reviewId}")
  .onDelete(async (snapshot, context) => {
    // PROBLEMA 2 CORRIGIDO: db dentro da função (após initializeApp)
    const db = admin.firestore();

    try {
      const reviewId = context.params.reviewId;
      const reviewData = snapshot.data();

      // Validar revieweeId
      const revieweeId = reviewData?.reviewee_id;
      if (!revieweeId || typeof revieweeId !== "string") {
        console.warn(
          "⚠️ [updateUserRating] revieweeId inválido " +
          "para review deletada " + reviewId
        );
        return;
      }

      console.log(
        "📊 [updateUserRating] Review deletada, recalculando rating " +
        "para usuário: " + revieweeId
      );

      // Buscar todas as reviews restantes do usuário
      const reviewsSnapshot = await db
        .collection("Reviews")
        .where("reviewee_id", "==", revieweeId)
        .get();

      if (reviewsSnapshot.empty) {
        console.log(
          "⚠️ [updateUserRating] Nenhuma review restante " +
          "para " + revieweeId + ", resetando rating para 0"
        );

        // PROBLEMA 4 CORRIGIDO: usar 0 explícito ao invés de delete
        await db.collection("Users").doc(revieweeId).set({
          overallRating: 0,
          totalReviews: 0,
          lastRatingUpdate: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        return;
      }

      // Calcular média dos ratings
      let sumRatings = 0;
      let validRatingsCount = 0;

      for (const doc of reviewsSnapshot.docs) {
        const reviewData = doc.data();
        const rating = extractRatingFromReview(reviewData);

        // PROBLEMA 5 AJUSTADO: ignorar reviews com rating 0
        if (rating > 0) {
          sumRatings += rating;
          validRatingsCount++;
        }
      }

      const overallRating = validRatingsCount > 0 ?
        Number((sumRatings / validRatingsCount).toFixed(2)) : 0;

      console.log(
        "✅ [updateUserRating] Rating recalculado: " + overallRating + " " +
        "(" + validRatingsCount + " reviews válidas)"
      );

      await db.collection("Users").doc(revieweeId).set({
        overallRating: overallRating,
        totalReviews: validRatingsCount,
        lastRatingUpdate: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      console.log(
        "🎯 [updateUserRating] Rating atualizado após delete " +
        "para " + revieweeId
      );
    } catch (error) {
      console.error(
        "❌ [updateUserRating] Erro ao atualizar rating após delete:",
        error
      );
    }
  });

/**
 * 🔧 Função HTTP para recalcular rating de um usuário específico
 * Útil para correções manuais ou migrações
 *
 * Uso:
 * POST https://us-central1-{project}.cloudfunctions.net/
 * recalculateUserRatingHttp
 * Body: { "userId": "abc123" }
 */
export const recalculateUserRatingHttp =
  functions.https.onRequest(async (req, res) => {
    // PROBLEMA 2 CORRIGIDO: db dentro da função (após initializeApp)
    const db = admin.firestore();

    // CORS
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    try {
      const {userId} = req.body;

      if (!userId || typeof userId !== "string") {
        res.status(400).json({error: "userId é obrigatório"});
        return;
      }

      console.log(
        "🔧 [recalculateUserRating] Recalculando manualmente " +
        "para: " + userId
      );

      // Buscar todas as reviews do usuário
      const reviewsSnapshot = await db
        .collection("Reviews")
        .where("reviewee_id", "==", userId)
        .get();
      if (reviewsSnapshot.empty) {
        await db.collection("Users").doc(userId).set({
          overallRating: 0,
          totalReviews: 0,
          lastRatingUpdate: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        res.json({
          success: true,
          overallRating: 0,
          totalReviews: 0,
          message: "Nenhuma review encontrada, rating resetado para 0",
        });
        return;
      }

      // Calcular média - PROBLEMA 1 CORRIGIDO:
      // usar mesma lógica das outras funções
      let sumRatings = 0;
      let validRatingsCount = 0;

      for (const doc of reviewsSnapshot.docs) {
        const reviewData = doc.data();
        const rating = extractRatingFromReview(reviewData);

        // PROBLEMA 5 AJUSTADO: ignorar reviews com rating 0
        if (rating > 0) {
          sumRatings += rating;
          validRatingsCount++;
        }
      }

      const overallRating = validRatingsCount > 0 ?
        Number((sumRatings / validRatingsCount).toFixed(2)) : 0;

      // Atualizar documento - PROBLEMA 4 CORRIGIDO: usar set com merge
      await db.collection("Users").doc(userId).set({
        overallRating: overallRating,
        totalReviews: validRatingsCount,
        lastRatingUpdate: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      res.json({
        success: true,
        overallRating,
        totalReviews: validRatingsCount,
        message: "Rating recalculado com sucesso",
      });
    } catch (error) {
      console.error("❌ [recalculateUserRating] Erro:", error);
      res.status(500).json({error: "Erro ao recalcular rating"});
    }
  });

