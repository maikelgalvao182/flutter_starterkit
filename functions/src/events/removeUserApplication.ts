import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Cloud Function para remover a aplicação de um usuário em um evento
 *
 * Operações realizadas:
 * 1. Valida que existe uma aplicação do usuário para o evento
 * 2. Remove registro em 'EventApplications'
 * 3. Remove usuário do array 'participants' em 'EventChats'
 * 4. Decrementa 'participantCount' no chat
 * 5. Remove conversa do evento do usuário
 *
 * @param eventId - ID do evento
 * @param userId - ID do usuário (opcional, se não fornecido usa o auth.uid)
 * @returns {success: boolean, message: string}
 */
export const removeUserApplication = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    // Verifica autenticação
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const {eventId, userId: targetUserId} = data;
    const currentUserId = context.auth.uid;

    // Se userId não for fornecido, usa o próprio usuário
    const userId = targetUserId || currentUserId;

    if (!eventId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "eventId is required"
      );
    }

    const firestore = admin.firestore();

    try {
      // Se estiver removendo outro usuário, verifica se é o criador do evento
      if (userId !== currentUserId) {
        const eventDoc = await firestore
          .collection("events")
          .doc(eventId)
          .get();

        if (!eventDoc.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "Event not found"
          );
        }

        const createdBy = eventDoc.data()?.createdBy;

        if (createdBy !== currentUserId) {
          throw new functions.https.HttpsError(
            "permission-denied",
            "Only the event creator can remove other participants"
          );
        }
      }

      console.log(`🚪 Removing application: event=${eventId}, user=${userId}`);

      // 1. Busca a aplicação do usuário
      const applicationSnapshot = await firestore
        .collection("EventApplications")
        .where("eventId", "==", eventId)
        .where("userId", "==", userId)
        .limit(1)
        .get();

      if (applicationSnapshot.empty) {
        throw new functions.https.HttpsError(
          "not-found",
          "Application not found"
        );
      }

      const applicationDoc = applicationSnapshot.docs[0];

      // 2. Inicia batch operation
      const batch = firestore.batch();

      // Remove aplicação
      batch.delete(applicationDoc.ref);

      // Atualiza EventChat (remove do array de participants e decrementa)
      const eventChatRef = firestore.collection("EventChats").doc(eventId);
      batch.update(eventChatRef, {
        participants: admin.firestore.FieldValue.arrayRemove(userId),
        participantCount: admin.firestore.FieldValue.increment(-1),
      });

      // Remove conversa do usuário
      const eventUserId = `event_${eventId}`;
      const conversationRef = firestore
        .collection("Connections")
        .doc(userId)
        .collection("conversations")
        .doc(eventUserId);
      batch.delete(conversationRef);

      // 3. Executa batch
      await batch.commit();

      console.log("✅ Application removed successfully");

      return {
        success: true,
        message: "Application removed successfully",
      };
    } catch (error: unknown) {
      console.error("❌ Error removing application:", error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      const err = error as Error;
      throw new functions.https.HttpsError(
        "internal",
        `Failed to remove application: ${err.message}`
      );
    }
  });

/**
 * Cloud Function para remover um participante específico (apenas criador)
 *
 * Esta é uma versão alternativa que permite ao criador remover
 * qualquer participante
 */
export const removeParticipant = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    // Verifica autenticação
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const {eventId, userId} = data;
    const currentUserId = context.auth.uid;

    if (!eventId || !userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "eventId and userId are required"
      );
    }

    const firestore = admin.firestore();

    try {
      // Verifica se é o criador do evento
      const eventDoc = await firestore.collection("events").doc(eventId).get();

      if (!eventDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Event not found"
        );
      }

      const createdBy = eventDoc.data()?.createdBy;

      if (createdBy !== currentUserId) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only the event creator can remove participants"
        );
      }

      // Não permite remover o próprio criador
      if (userId === currentUserId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Event creator cannot remove themselves"
        );
      }

      console.log(
        "👤 Removing participant: " +
          `event=${eventId}, user=${userId}, by=${currentUserId}`
      );

      // Busca a aplicação do usuário
      const applicationSnapshot = await firestore
        .collection("EventApplications")
        .where("eventId", "==", eventId)
        .where("userId", "==", userId)
        .limit(1)
        .get();

      if (applicationSnapshot.empty) {
        throw new functions.https.HttpsError(
          "not-found",
          "Participant application not found"
        );
      }

      const applicationDoc = applicationSnapshot.docs[0];

      // Inicia batch operation
      const batch = firestore.batch();

      // Remove aplicação
      batch.delete(applicationDoc.ref);

      // Atualiza EventChat
      const eventChatRef = firestore.collection("EventChats").doc(eventId);
      batch.update(eventChatRef, {
        participants: admin.firestore.FieldValue.arrayRemove(userId),
        participantCount: admin.firestore.FieldValue.increment(-1),
      });

      // Remove conversa do usuário
      const eventUserId = `event_${eventId}`;
      const conversationRef = firestore
        .collection("Connections")
        .doc(userId)
        .collection("conversations")
        .doc(eventUserId);
      batch.delete(conversationRef);

      // Executa batch
      await batch.commit();

      console.log("✅ Participant removed successfully");

      return {
        success: true,
        message: "Participant removed successfully",
      };
    } catch (error: unknown) {
      console.error("❌ Error removing participant:", error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      const err = error as Error;
      throw new functions.https.HttpsError(
        "internal",
        `Failed to remove participant: ${err.message}`
      );
    }
  });
