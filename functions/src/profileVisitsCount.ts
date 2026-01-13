import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const getProfileVisitsCount = functions.https.onCall(
  async (data, context) => {
    const authUserId = context.auth?.uid;
    if (!authUserId) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "O usuário precisa estar logado para consultar visitas."
      );
    }

    const requestedUserId = (data?.userId as string | undefined) ?? authUserId;
    if (requestedUserId !== authUserId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Você só pode consultar as suas próprias visitas."
      );
    }

    try {
      const snapshot = await admin
        .firestore()
        .collection("ProfileVisits")
        .where("visitedUserId", "==", authUserId)
        .get();

      let total = 0;
      for (const doc of snapshot.docs) {
        const value = doc.data()?.visitCount;
        if (typeof value === "number") {
          total += value;
        } else {
          total += 1;
        }
      }

      return {count: total};
    } catch (error) {
      console.error("❌ [getProfileVisitsCount] Erro:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Não foi possível calcular suas visitas no momento."
      );
    }
  }
);
