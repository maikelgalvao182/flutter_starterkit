/**
 * Cloud Functions: Push Notifications para Chat 1-1
 *
 * IMPORTANTE: Esta função envia APENAS notificações push (FCM).
 * NÃO salva na coleção Notifications (in-app).
 *
 * Monitora:
 * - Messages/{userId}/{partnerId}/{messageId} (chat 1-1)
 * - EventChats/{eventId}/Messages/{messageId} (chat de grupo)
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

/**
 * Trigger: Mensagens 1-1
 * Path: Messages/{senderId}/{receiverId}/{messageId}
 *
 * Envia push notification para o receiverId quando uma nova mensagem é criada
 */
export const onPrivateMessageCreated = functions.firestore
  .document("Messages/{senderId}/{receiverId}/{messageId}")
  .onCreate(async (snap, context) => {
    const senderId = context.params.senderId;
    const receiverId = context.params.receiverId;
    const messageId = context.params.messageId;
    const messageData = snap.data();

    if (!messageData) {
      console.error("❌ [ChatPush] Mensagem sem dados:", messageId);
      return;
    }

    try {
      console.log("📬 [ChatPush] Nova mensagem 1-1");
      console.log(`   De: ${senderId}`);
      console.log(`   Para: ${receiverId}`);
      console.log(`   ID: ${messageId}`);

      // Extrair dados da mensagem
      const messageText =
        messageData.message_text || messageData.message || "";
      const messageType =
        messageData.message_type || messageData.messageType || "text";
      const senderName =
        messageData.user_fullname || messageData.userFullname || "Alguém";
      const timestamp =
        messageData.timestamp || admin.firestore.FieldValue.serverTimestamp();

      console.log(`   Remetente: ${senderName}`);
      console.log(`   Tipo: ${messageType}`);
      console.log(`   Preview: ${messageText.substring(0, 50)}...`);

      // Buscar FCM tokens do receiver na coleção DeviceTokens
      const tokensSnapshot = await admin
        .firestore()
        .collection("DeviceTokens")
        .where("userId", "==", receiverId)
        .get();

      if (tokensSnapshot.empty) {
        console.warn(`⚠️ [ChatPush] Receiver sem tokens FCM: ${receiverId}`);
        return;
      }

      const fcmTokens = tokensSnapshot.docs
        .map((doc) => doc.data().token)
        .filter((token) => token && token.length > 0);

      if (fcmTokens.length === 0) {
        console.warn(
          `⚠️ [ChatPush] Receiver sem tokens válidos: ${receiverId}`,
        );
        return;
      }

      console.log(
        `📱 [ChatPush] Encontrados ${fcmTokens.length} dispositivo(s)`,
      );

      // Preparar preview da mensagem
      let messagePreview = "";
      if (messageType === "image") {
        messagePreview = "📷 Imagem";
      } else {
        messagePreview = messageText.substring(0, 100);
      }

      // Enviar push notification para todos os dispositivos
      console.log(
        `🚀 [ChatPush] Enviando push para ${fcmTokens.length} dispositivo(s)`,
      );
      const response = await admin.messaging().sendEachForMulticast({
        tokens: fcmTokens,
        notification: {
          title: "Nova mensagem",
          body: `${senderName}: ${messagePreview}`,
        },
        data: {
          type: "chat_message",
          senderId: senderId,
          senderName: senderName,
          messagePreview: messagePreview,
          messageType: messageType,
          timestamp: timestamp.toString(),
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });

      console.log("✅ [ChatPush] Push enviado com sucesso");
      console.log(`   Success: ${response.successCount}`);
      console.log(`   Failure: ${response.failureCount}`);

      // Limpar tokens inválidos
      if (response.failureCount > 0) {
        const batch = admin.firestore().batch();
        response.responses.forEach((result, index) => {
          if (!result.success && result.error) {
            const errorCode = result.error.code;
            if (
              errorCode === "messaging/invalid-registration-token" ||
              errorCode === "messaging/registration-token-not-registered"
            ) {
              const tokenDoc = tokensSnapshot.docs[index];
              console.warn(
                `⚠️ [ChatPush] Removendo token inválido: ${tokenDoc.id}`,
              );
              batch.delete(tokenDoc.ref);
            }
          }
        });
        await batch.commit();
      }
    } catch (error) {
      console.error("❌ [ChatPush] Erro ao enviar push:", error);
    }
  });

/**
 * Trigger: Mensagens de EventChat
 * Path: EventChats/{eventId}/Messages/{messageId}
 *
 * Envia push notification para todos os participantes (exceto o remetente)
 */
export const onEventChatMessageCreatedPush = functions.firestore
  .document("EventChats/{eventId}/Messages/{messageId}")
  .onCreate(async (snap, context) => {
    const eventId = context.params.eventId;
    const messageId = context.params.messageId;
    const messageData = snap.data();

    if (!messageData) {
      console.error("❌ [EventChatPush] Mensagem sem dados:", messageId);
      return;
    }

    try {
      console.log("📬 [EventChatPush] Nova mensagem no evento");
      console.log(`   Evento: ${eventId}`);
      console.log(`   Mensagem: ${messageId}`);

      const senderId = messageData.sender_id || messageData.senderId;
      const messageText =
        messageData.message_text || messageData.message || "";
      const messageType =
        messageData.message_type || messageData.messageType || "text";
      const senderName =
        messageData.sender_name || messageData.senderName || "Alguém";
      const timestamp =
        messageData.timestamp || admin.firestore.FieldValue.serverTimestamp();

      console.log(`   Remetente: ${senderName} (${senderId})`);
      console.log(`   Tipo: ${messageType}`);

      // Buscar dados do evento
      const eventChatDoc = await admin
        .firestore()
        .collection("EventChats")
        .doc(eventId)
        .get();

      if (!eventChatDoc.exists) {
        console.warn(
          `⚠️ [EventChatPush] EventChat não encontrado: ${eventId}`,
        );
        return;
      }

      const eventChatData = eventChatDoc.data();
      const participantIds = (eventChatData?.participantIds || []) as string[];
      const eventTitle = eventChatData?.title || "Grupo";
      const eventEmoji = eventChatData?.emoji || "💬";

      console.log(`   Evento: ${eventTitle} ${eventEmoji}`);
      console.log(`   Participantes: ${participantIds.length}`);

      // Filtrar participantes (excluir o remetente)
      const receivers = participantIds.filter((id) => id !== senderId);

      if (receivers.length === 0) {
        console.log(
          "⚠️ [EventChatPush] Nenhum receiver (apenas remetente no grupo)",
        );
        return;
      }

      console.log(`   Receivers: ${receivers.length}`);

      // Preparar preview da mensagem
      let messagePreview = "";
      if (messageType === "image") {
        messagePreview = "📷 Imagem";
      } else {
        messagePreview = messageText.substring(0, 100);
      }

      // Buscar FCM tokens de todos os receivers na coleção DeviceTokens
      console.log(
        `🔍 [EventChatPush] Buscando tokens para ${receivers.length} usuários`,
      );

      const tokens: string[] = [];
      const tokenDocs: FirebaseFirestore.QueryDocumentSnapshot[] = [];

      // Buscar tokens em batch (max 10 por vez)
      const batchSize = 10;
      for (let i = 0; i < receivers.length; i += batchSize) {
        const batch = receivers.slice(i, i + batchSize);
        const tokensSnapshot = await admin
          .firestore()
          .collection("DeviceTokens")
          .where("userId", "in", batch)
          .get();

        tokensSnapshot.docs.forEach((doc) => {
          const token = doc.data().token;
          if (token && token.length > 0) {
            tokens.push(token);
            tokenDocs.push(doc);
          }
        });
      }

      if (tokens.length === 0) {
        console.warn("⚠️ [EventChatPush] Nenhum receiver com FCM token");
        return;
      }

      console.log(
        `🚀 [EventChatPush] Enviando push para ${tokens.length} dispositivo(s)`,
      );

      // Enviar para múltiplos dispositivos usando multicast
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        notification: {
          title: `${eventTitle} ${eventEmoji}`,
          body: `${senderName}: ${messagePreview}`,
        },
        data: {
          type: "event_chat_message",
          eventId: eventId,
          senderId: senderId,
          senderName: senderName,
          eventTitle: eventTitle,
          eventEmoji: eventEmoji,
          messagePreview: messagePreview,
          messageType: messageType,
          timestamp: timestamp.toString(),
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });

      console.log("✅ [EventChatPush] Push enviado");
      console.log(`   Success: ${response.successCount}`);
      console.log(`   Failure: ${response.failureCount}`);

      // Limpar tokens inválidos
      if (response.failureCount > 0) {
        const batch = admin.firestore().batch();
        response.responses.forEach((result, index) => {
          if (!result.success && result.error) {
            const errorCode = result.error.code;
            if (
              errorCode === "messaging/invalid-registration-token" ||
              errorCode === "messaging/registration-token-not-registered"
            ) {
              const tokenDoc = tokenDocs[index];
              console.warn(
                `⚠️ [EventChatPush] Removendo token inválido: ${tokenDoc.id}`,
              );
              batch.delete(tokenDoc.ref);
            }
          }
        });
        await batch.commit();
      }
    } catch (error) {
      console.error("❌ [EventChatPush] Erro ao enviar push:", error);
    }
  });
