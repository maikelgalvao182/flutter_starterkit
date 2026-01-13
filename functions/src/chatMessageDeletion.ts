/* eslint-disable require-jsdoc, max-len */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

type DeleteChatMessagePayload = {
  conversationId?: string;
  messageId?: string;
};

function asTrimmedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((v) => typeof v === "string" && v.trim().length > 0);
}

function extractParticipantIds(eventChatData: FirebaseFirestore.DocumentData): string[] {
  // Suporta ambos schemas:
  // - participantIds: string[]
  // - participants: string[]
  // - participants.participantIds: string[]
  const direct = asStringArray(eventChatData["participantIds"]);
  if (direct.length > 0) return direct;

  const legacy = asStringArray(eventChatData["participants"]);
  if (legacy.length > 0) return legacy;

  const nested = eventChatData["participants"];
  if (nested && typeof nested === "object") {
    const participantIds = asStringArray(
      (nested as Record<string, unknown>)["participantIds"]
    );
    if (participantIds.length > 0) return participantIds;
  }

  return [];
}

function extractModeratorIds(eventChatData: FirebaseFirestore.DocumentData): string[] {
  // Campos comuns possíveis (não existe um contrato único hoje)
  const direct = asStringArray(eventChatData["moderatorIds"]);
  if (direct.length > 0) return direct;

  const legacySnake = asStringArray(eventChatData["moderator_ids"]);
  if (legacySnake.length > 0) return legacySnake;

  const admins = asStringArray(eventChatData["adminIds"]);
  if (admins.length > 0) return admins;

  const adminsSnake = asStringArray(eventChatData["admin_ids"]);
  if (adminsSnake.length > 0) return adminsSnake;

  const moderators = asStringArray(eventChatData["moderators"]);
  if (moderators.length > 0) return moderators;

  const adminsAlt = asStringArray(eventChatData["admins"]);
  if (adminsAlt.length > 0) return adminsAlt;

  return [];
}

function timestampsEqual(a: unknown, b: unknown): boolean {
  // Firestore admin Timestamp shape
  const isTimestampLike = (v: unknown): v is {seconds: number; nanoseconds: number} => {
    if (!v || typeof v !== "object") return false;
    const obj = v as {seconds?: unknown; nanoseconds?: unknown};
    return typeof obj.seconds === "number" && typeof obj.nanoseconds === "number";
  };

  // Se ambos são Timestamp-like, compara com precisão total
  if (isTimestampLike(a) && isTimestampLike(b)) {
    return a.seconds === b.seconds && a.nanoseconds === b.nanoseconds;
  }

  const toMillis = (v: unknown): number | null => {
    if (v == null) return null;
    if (v instanceof Date) return v.getTime();
    if (typeof v === "number") return v;
    if (typeof v === "string") {
      const parsed = Date.parse(v);
      return Number.isNaN(parsed) ? null : parsed;
    }
    if (typeof v === "object") {
      const anyV = v as Record<string, unknown> & {
        toMillis?: () => number;
        toDate?: () => Date;
        seconds?: number;
        nanoseconds?: number;
      };

      if (typeof anyV.toMillis === "function") {
        try {
          const n = anyV.toMillis();
          return typeof n === "number" ? n : null;
        } catch (_) {
          return null;
        }
      }

      if (typeof anyV.toDate === "function") {
        try {
          const d = anyV.toDate();
          return d instanceof Date ? d.getTime() : null;
        } catch (_) {
          return null;
        }
      }

      if (typeof anyV.seconds === "number") {
        const nanos = typeof anyV.nanoseconds === "number" ? anyV.nanoseconds : 0;
        return anyV.seconds * 1000 + Math.floor(nanos / 1e6);
      }
    }

    return null;
  };

  const ams = toMillis(a);
  const bms = toMillis(b);
  if (ams == null || bms == null) return false;
  return ams === bms;
}

function isMessageAuthoredBy(
  msg: FirebaseFirestore.DocumentData,
  senderId: string,
  receiverId: string
): boolean {
  const msgSenderId = asTrimmedString(msg["sender_id"]);
  // receiver_id pode não existir em mensagens legacy (o path já implica o receiver).
  const msgReceiverId = asTrimmedString(msg["receiver_id"]);
  if (msgSenderId !== senderId) return false;
  if (msgReceiverId.length === 0) return true;
  return msgReceiverId === receiverId;
}

export const deleteChatMessage = functions.https.onCall(
  async (data: DeleteChatMessagePayload, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Usuário não autenticado"
      );
    }

    const conversationId = asTrimmedString(data.conversationId);
    const messageId = asTrimmedString(data.messageId);

    if (!conversationId || !messageId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "conversationId/messageId são obrigatórios"
      );
    }

    // Defesa barata: evita IDs com '/' (path traversal). O Firestore já impede,
    // mas bloquear cedo deixa o erro mais claro e reduz superfície.
    if (conversationId.includes("/") || messageId.includes("/")) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "IDs inválidos"
      );
    }

    functions.logger.info("[deleteChatMessage] request", {
      uid,
      conversationId,
      messageId,
      isEvent: conversationId.startsWith("event_"),
    });

    const db = admin.firestore();

    const isNotDeleted = (docData: FirebaseFirestore.DocumentData): boolean => {
      return docData["is_deleted"] !== true;
    };

    const extractMessageText = (docData: FirebaseFirestore.DocumentData): string => {
      return String(docData["message_text"] ?? docData["message"] ?? "");
    };

    const extractMessageType = (docData: FirebaseFirestore.DocumentData): string => {
      return String(docData["message_type"] ?? docData["messageType"] ?? "text");
    };

    const softDeletePatch: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = {
      is_deleted: true,
      deleted_at: admin.firestore.FieldValue.serverTimestamp(),
      deleted_by: uid,
    };

    // 🎯 EVENTO/GRUPO
    if (conversationId.startsWith("event_")) {
      const eventId = conversationId.replace("event_", "").trim();
      if (!eventId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "eventId inválido"
        );
      }

      // Buscar EventChats primeiro (costuma conter createdBy/participants)
      const eventChatDoc = await db.collection("EventChats").doc(eventId).get();
      const eventChatData = eventChatDoc.exists ? (eventChatDoc.data() ?? {}) : {};
      const participantIds = eventChatDoc.exists ?
        extractParticipantIds(eventChatData) :
        [];
      const moderatorIds = eventChatDoc.exists ?
        extractModeratorIds(eventChatData) :
        [];

      // Fallback: createdBy pode vir do events/{eventId}
      let createdBy = asTrimmedString(eventChatData["createdBy"]);
      if (!createdBy) {
        const eventSnap = await db.collection("events").doc(eventId).get();
        if (!eventSnap.exists) {
          throw new functions.https.HttpsError("not-found", "Evento não encontrado");
        }

        createdBy = asTrimmedString(eventSnap.data()?.createdBy);
        if (!createdBy) {
          functions.logger.error("[deleteChatMessage] event missing createdBy", {
            uid,
            eventId,
          });
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Evento inválido"
          );
        }
      }

      const msgRef = db
        .collection("EventChats")
        .doc(eventId)
        .collection("Messages")
        .doc(messageId);

      const msgSnap = await msgRef.get();
      if (!msgSnap.exists) {
        // Idempotência: se já não existe, retorna ok.
        functions.logger.warn("[deleteChatMessage] event message not found", {
          uid,
          eventId,
          messageId,
        });
        return {ok: true, status: "missing"};
      }

      const msg = msgSnap.data() ?? {};
      const senderId = asTrimmedString(msg["sender_id"]);
      if (!senderId) {
        functions.logger.error("[deleteChatMessage] event message missing sender_id", {
          uid,
          eventId,
          messageId,
        });
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Mensagem inválida"
        );
      }

      // Permite deletar se:
      // - quem chamou é o autor da mensagem, OU
      // - é o criador do evento
      const isCreator = createdBy === uid;
      const isAuthor = senderId === uid;

      // Membership check (best-effort): se temos participantIds, exige que o usuário esteja no chat
      // (exceto creator/moderador). Isso reduz superfície de ataque por eventId/messageId guess.
      const isParticipant = participantIds.includes(uid);
      const isModerator = moderatorIds.includes(uid);

      const isAllowed = isAuthor || isCreator || isModerator;
      const failsMembership = participantIds.length > 0 &&
        !isParticipant &&
        !isCreator &&
        !isModerator;

      // 1) Membership gate (quando temos lista de participantes):
      // evita que alguém fora do evento tente apagar via eventId/messageId guess.
      if (failsMembership) {
        functions.logger.warn("[deleteChatMessage] permission-denied (event) not participant", {
          uid,
          eventId,
          messageId,
          isParticipant,
          isCreator,
          isModerator,
        });
        throw new functions.https.HttpsError(
          "permission-denied",
          "Sem permissão para deletar esta mensagem"
        );
      }

      // 2) Role/autoria gate: participante comum não apaga mensagem de terceiros.
      if (!isAllowed) {
        functions.logger.warn("[deleteChatMessage] permission-denied (event) insufficient role", {
          uid,
          eventId,
          messageId,
          senderId,
          createdBy,
          isParticipant,
          isModerator,
        });
        throw new functions.https.HttpsError(
          "permission-denied",
          "Sem permissão para deletar esta mensagem"
        );
      }

      // Determinar se a mensagem deletada era o "último preview efetivo" (última NÃO deletada).
      // Fazemos isso ANTES do soft delete para evitar que uma msg já deletada continue como "latest".
      let shouldUpdatePreviews = false;
      let recentMessages: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>[] = [];
      try {
        const latestSnap = await db
          .collection("EventChats")
          .doc(eventId)
          .collection("Messages")
          .orderBy("timestamp", "desc")
          .limit(200)
          .get();
        recentMessages = latestSnap.docs;

        const effectiveLatest = recentMessages.find((d) => {
          const data = d.data() ?? {};
          return data["is_deleted"] !== true;
        });

        shouldUpdatePreviews = effectiveLatest?.id === messageId;
      } catch (err) {
        functions.logger.warn("[deleteChatMessage] failed to check latest effective event message", {
          uid,
          eventId,
          messageId,
          error: (err as Error)?.message,
        });
        shouldUpdatePreviews = false;
      }

      // Soft delete idempotente.
      await msgRef.set(softDeletePatch, {merge: true});

      let updatedPreviews = 0;
      if (shouldUpdatePreviews && participantIds.length > 0) {
        // Recalcular o preview para a última mensagem não deletada.
        // Evita queries com where("is_deleted", ...) (que pode exigir índice e não cobre missing field).
        let replacementDoc = recentMessages.find((d) => {
          if (d.id === messageId) return false;
          const data = d.data() ?? {};
          return isNotDeleted(data);
        });

        // Se não achou replacement no lote (evento muito ativo/deletado), tenta uma query direta.
        // Isso funciona bem daqui pra frente porque mensagens novas passam a ter is_deleted=false.
        if (!replacementDoc) {
          try {
            const q = await db
              .collection("EventChats")
              .doc(eventId)
              .collection("Messages")
              .where("is_deleted", "==", false)
              .orderBy("timestamp", "desc")
              .limit(1)
              .get();
            replacementDoc = q.docs[0];
          } catch (err) {
            functions.logger.warn("[deleteChatMessage] event replacement where(is_deleted==false) failed", {
              uid,
              eventId,
              messageId,
              error: (err as Error)?.message,
            });
          }
        }

        // Último fallback: paginação limitada procurando um doc com is_deleted != true.
        // Só roda se realmente necessário (pouco frequente) e é capado para não explodir custos.
        if (!replacementDoc && recentMessages.length > 0) {
          try {
            const messagesCol = db
              .collection("EventChats")
              .doc(eventId)
              .collection("Messages");

            let lastDoc = recentMessages[recentMessages.length - 1];
            for (let attempt = 0; attempt < 5; attempt += 1) {
              const page = await messagesCol
                .orderBy("timestamp", "desc")
                .startAfter(lastDoc)
                .limit(200)
                .get();

              if (page.empty) break;
              const found = page.docs.find((d) => {
                if (d.id === messageId) return false;
                const data = d.data() ?? {};
                return isNotDeleted(data);
              });

              if (found) {
                replacementDoc = found;
                break;
              }

              lastDoc = page.docs[page.docs.length - 1];
            }
          } catch (err) {
            functions.logger.warn("[deleteChatMessage] event replacement pagination failed", {
              uid,
              eventId,
              messageId,
              error: (err as Error)?.message,
            });
          }
        }

        const replacementData = replacementDoc?.data() ?? null;
        const replacementText = replacementData ? extractMessageText(replacementData) : "";
        const replacementType = replacementData ? extractMessageType(replacementData) : "text";
        const replacementTimestamp = replacementData ?
          (replacementData["timestamp"] ?? null) :
          null;

        const conversationPatch: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = replacementData ?
          {
            last_message: replacementText,
            last_message_type: replacementType,
            last_message_is_deleted: false,
            // compatibilidade: app lê `timestamp` e também aceita `lastMessageAt`
            timestamp: replacementTimestamp ?? admin.firestore.FieldValue.serverTimestamp(),
            lastMessageAt: replacementTimestamp ?? admin.firestore.FieldValue.serverTimestamp(),
            last_message_timestamp: replacementTimestamp ?? admin.firestore.FieldValue.serverTimestamp(),
          } :
          {
            last_message: "",
            last_message_type: "text",
            last_message_is_deleted: true,
          };

        // Evitar estourar limite de batch em eventos grandes.
        const CHUNK_SIZE = 400;
        for (let i = 0; i < participantIds.length; i += CHUNK_SIZE) {
          const chunk = participantIds.slice(i, i + CHUNK_SIZE);
          const batch = db.batch();

          for (const participantId of chunk) {
            const conversationRef = db
              .collection("Connections")
              .doc(participantId)
              .collection("Conversations")
              .doc(`event_${eventId}`);

            batch.set(
              conversationRef,
              conversationPatch,
              {merge: true}
            );
            updatedPreviews += 1;
          }

          await batch.commit();
        }

        // Também atualiza o EventChats doc (source of truth pro backend).
        if (eventChatDoc.exists) {
          const eventChatPatch: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = replacementData ?
            {
              lastMessage: replacementText,
              lastMessageType: replacementType,
              lastMessageIsDeleted: false,
              lastMessageAt: replacementTimestamp ?? admin.firestore.FieldValue.serverTimestamp(),
            } :
            {
              lastMessage: "",
              lastMessageIsDeleted: true,
            };

          await eventChatDoc.ref.set(
            eventChatPatch,
            {merge: true}
          );
        }
      }

      functions.logger.info("[deleteChatMessage] event soft-deleted", {
        uid,
        eventId,
        messageId,
        updatedPreviews,
      });

      return {ok: true, updatedPreviews};
    }

    // 👤 1:1
    if (conversationId === uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "conversationId inválido"
      );
    }

    const otherUserId = conversationId;

    if (otherUserId.includes("/")) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "conversationId inválido"
      );
    }

    const ownRef = db
      .collection("Messages")
      .doc(uid)
      .collection(otherUserId)
      .doc(messageId);

    const ownSnap = await ownRef.get();
    if (!ownSnap.exists) {
      // Idempotência: se a mensagem não existe do lado do autor, consideramos ok.
      functions.logger.warn("[deleteChatMessage] 1:1 own message not found", {
        uid,
        otherUserId,
        messageId,
      });
      return {ok: true, status: "missing"};
    }

    const own = ownSnap.data() ?? {};
    const senderId = asTrimmedString(own["sender_id"]);

    // Por padrão: apenas o autor pode apagar "para todos".
    if (senderId !== uid) {
      functions.logger.warn("[deleteChatMessage] permission-denied (1:1) not author", {
        uid,
        otherUserId,
        messageId,
        senderId,
      });
      throw new functions.https.HttpsError(
        "permission-denied",
        "Apenas o autor pode deletar para todos"
      );
    }

    // Membership check (best-effort): se não houver conversa registrada, loga.
    // Não bloqueia para evitar travar deleções em conversas inconsistentes.
    const convRef = db
      .collection("Connections")
      .doc(uid)
      .collection("Conversations")
      .doc(otherUserId);
    const convSnap = await convRef.get();
    if (!convSnap.exists) {
      functions.logger.warn("[deleteChatMessage] missing conversation doc (1:1)", {
        uid,
        otherUserId,
        messageId,
      });
    }

    // Soft delete do lado do autor (idempotente).
    await ownRef.set(softDeletePatch, {merge: true});

    // Em seguida, tenta remover a cópia do outro usuário com validação.
    const globalId = asTrimmedString(own["global_id"]) ||
      asTrimmedString(own["message_global_id"]) ||
      messageId;

    let deletedOther = 0;
    const warnings: string[] = [];

    // Preferência: IDs iguais nos dois lados.
    const directOtherRef = db
      .collection("Messages")
      .doc(otherUserId)
      .collection(uid)
      .doc(messageId);

    const directOtherSnap = await directOtherRef.get();
    if (directOtherSnap.exists) {
      const otherMsg = directOtherSnap.data() ?? {};
      // Segurança: só apaga se a mensagem do outro lado foi de fato enviada por uid.
      if (isMessageAuthoredBy(otherMsg, uid, otherUserId)) {
        await directOtherRef.set(softDeletePatch, {merge: true});
        deletedOther += 1;
      }
    }

    // Fallback para mensagens antigas (IDs diferentes): buscar pelo global_id / message_global_id.
    if (deletedOther === 0 && globalId) {
      const otherCollection = db
        .collection("Messages")
        .doc(otherUserId)
        .collection(uid);

      try {
        const byGlobalId = await otherCollection
          .where("global_id", "==", globalId)
          .limit(1)
          .get();
        const doc = byGlobalId.docs[0];
        if (doc) {
          const otherMsg = doc.data() ?? {};
          if (isMessageAuthoredBy(otherMsg, uid, otherUserId)) {
            await doc.ref.set(softDeletePatch, {merge: true});
            deletedOther += 1;
          }
        }
      } catch (err) {
        warnings.push("fallback_global_id_failed");
        functions.logger.warn("[deleteChatMessage] fallback global_id failed", {
          uid,
          otherUserId,
          messageId,
          globalId,
          error: (err as Error)?.message,
        });
      }

      if (deletedOther === 0) {
        try {
          const byMessageGlobalId = await otherCollection
            .where("message_global_id", "==", globalId)
            .limit(1)
            .get();
          const doc = byMessageGlobalId.docs[0];
          if (doc) {
            const otherMsg = doc.data() ?? {};
            if (isMessageAuthoredBy(otherMsg, uid, otherUserId)) {
              await doc.ref.set(softDeletePatch, {merge: true});
              deletedOther += 1;
            }
          }
        } catch (err) {
          warnings.push("fallback_message_global_id_failed");
          functions.logger.warn(
            "[deleteChatMessage] fallback message_global_id failed",
            {
              uid,
              otherUserId,
              messageId,
              globalId,
              error: (err as Error)?.message,
            }
          );
        }
      }
    }

    // Atualizar preview (best-effort) se essa era a última mensagem.
    const msgTimestamp = own["timestamp"];
    let updatedPreviews = 0;
    try {
      const receiverConvRef = db
        .collection("Connections")
        .doc(otherUserId)
        .collection("Conversations")
        .doc(uid);

      const [senderConvSnap, receiverConvSnap] = await Promise.all([
        // Reusa o convSnap já lido anteriormente quando possível
        Promise.resolve(convSnap),
        receiverConvRef.get(),
      ]);

      const senderConvData = senderConvSnap.exists ? (senderConvSnap.data() ?? {}) : {};
      const receiverConvData = receiverConvSnap.exists ? (receiverConvSnap.data() ?? {}) : {};

      const extractLastMessageId = (data: FirebaseFirestore.DocumentData): string => {
        return (
          asTrimmedString(data["lastMessageId"]) ||
          asTrimmedString(data["last_message_id"]) ||
          asTrimmedString(data["last_messageId"]) ||
          asTrimmedString(data["lastMessageID"]) ||
          ""
        );
      };

      const senderLastId = extractLastMessageId(senderConvData);
      const receiverLastId = extractLastMessageId(receiverConvData);

      const senderConvTs = senderConvData["timestamp"] ?? senderConvData["lastMessageAt"] ?? senderConvData["last_message_at"];
      const receiverConvTs = receiverConvData["timestamp"] ?? receiverConvData["lastMessageAt"] ?? receiverConvData["last_message_at"];

      // Preferência: comparar por lastMessageId (determinístico). Fallback para timestamp em dados legados.
      const matchesId = (lastId: string): boolean => {
        if (!lastId) return false;
        return lastId === messageId || lastId === globalId;
      };

      const shouldUpdateSender = senderLastId ?
        matchesId(senderLastId) :
        timestampsEqual(senderConvTs, msgTimestamp);

      const shouldUpdateReceiver = receiverLastId ?
        matchesId(receiverLastId) :
        timestampsEqual(receiverConvTs, msgTimestamp);

      if (shouldUpdateSender || shouldUpdateReceiver) {
        // Recalcular preview para a última mensagem não deletada (igual ao evento).
        const readReplacement = async (
          ownerId: string,
          peerId: string
        ): Promise<{
          text: string;
          type: string;
          timestamp: unknown;
          id: string;
        } | null> => {
          const col = db
            .collection("Messages")
            .doc(ownerId)
            .collection(peerId);

          // Lote recente
          const recent = await col.orderBy("timestamp", "desc").limit(200).get();
          const found = recent.docs.find((d) => {
            if (d.id === messageId) return false;
            const data = d.data() ?? {};
            return isNotDeleted(data);
          });

          if (found) {
            const data = found.data() ?? {};
            return {
              id: found.id,
              text: extractMessageText(data),
              type: extractMessageType(data),
              timestamp: data["timestamp"],
            };
          }

          // Tenta query direta (melhor para mensagens novas com is_deleted=false)
          try {
            const q = await col
              .where("is_deleted", "==", false)
              .orderBy("timestamp", "desc")
              .limit(1)
              .get();
            const doc = q.docs[0];
            if (doc) {
              const data = doc.data() ?? {};
              return {
                id: doc.id,
                text: extractMessageText(data),
                type: extractMessageType(data),
                timestamp: data["timestamp"],
              };
            }
          } catch (_) {
            // Ignora (índice pode não existir). Fallback é simplesmente não recalcular.
          }

          // Último fallback: paginação limitada (casos raros onde as últimas N estão deletadas).
          if (!recent.empty) {
            try {
              let lastDoc = recent.docs[recent.docs.length - 1];
              for (let attempt = 0; attempt < 5; attempt += 1) {
                const page = await col
                  .orderBy("timestamp", "desc")
                  .startAfter(lastDoc)
                  .limit(200)
                  .get();
                if (page.empty) break;

                const older = page.docs.find((d) => {
                  if (d.id === messageId) return false;
                  const data = d.data() ?? {};
                  return isNotDeleted(data);
                });

                if (older) {
                  const data = older.data() ?? {};
                  return {
                    id: older.id,
                    text: extractMessageText(data),
                    type: extractMessageType(data),
                    timestamp: data["timestamp"],
                  };
                }

                lastDoc = page.docs[page.docs.length - 1];
              }
            } catch (_) {
              // Best-effort: se falhar, segue sem replacement.
            }
          }

          return null;
        };

        const batch = db.batch();

        if (shouldUpdateSender && senderConvSnap.exists) {
          const replacement = await readReplacement(uid, otherUserId);
          if (replacement) {
            const ts = replacement.timestamp ?? admin.firestore.FieldValue.serverTimestamp();
            batch.set(
              senderConvSnap.ref,
              {
                last_message: replacement.text,
                last_message_type: replacement.type,
                last_message_is_deleted: false,
                lastMessageId: replacement.id,
                lastMessageAt: ts,
                last_message_timestamp: ts,
                timestamp: ts,
              },
              {merge: true}
            );
          } else {
            batch.set(
              senderConvSnap.ref,
              {last_message: "", last_message_is_deleted: true},
              {merge: true}
            );
          }
          updatedPreviews += 1;
        }

        if (shouldUpdateReceiver && receiverConvSnap.exists) {
          const replacement = await readReplacement(otherUserId, uid);
          if (replacement) {
            const ts = replacement.timestamp ?? admin.firestore.FieldValue.serverTimestamp();
            batch.set(
              receiverConvSnap.ref,
              {
                last_message: replacement.text,
                last_message_type: replacement.type,
                last_message_is_deleted: false,
                lastMessageId: replacement.id,
                lastMessageAt: ts,
                last_message_timestamp: ts,
                timestamp: ts,
              },
              {merge: true}
            );
          } else {
            batch.set(
              receiverConvSnap.ref,
              {last_message: "", last_message_is_deleted: true},
              {merge: true}
            );
          }
          updatedPreviews += 1;
        }

        await batch.commit();
      }
    } catch (err) {
      warnings.push("update_previews_failed");
      functions.logger.warn("[deleteChatMessage] update previews failed", {
        uid,
        otherUserId,
        messageId,
        error: (err as Error)?.message,
      });
    }

    functions.logger.info("[deleteChatMessage] 1:1 soft-deleted", {
      uid,
      otherUserId,
      messageId,
      deletedOther,
      updatedPreviews,
      warnings,
    });

    return {ok: true, deletedOther, updatedPreviews, warnings};
  }
);
