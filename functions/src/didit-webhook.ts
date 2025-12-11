/* eslint-disable @typescript-eslint/no-var-requires */
/* eslint-disable camelcase */
/* eslint-disable max-len */
/* eslint-disable @typescript-eslint/no-explicit-any */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

// Inicializa o Firebase Admin (apenas uma vez)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Webhook do Didit para receber notificações de verificação
 *
 * Endpoint: https://us-central1-partiu-479902.cloudfunctions.net/diditWebhook
 *
 * Funcionalidades:
 * - Valida assinatura HMAC do webhook
 * - Verifica timestamp (máximo 5 minutos)
 * - Processa eventos de status e dados
 * - Atualiza sessão no Firestore
 * - Salva verificação aprovada automaticamente
 */
exports.diditWebhook = functions.https.onRequest(async (req: any, res: any) => {
  // Configurar CORS se necessário
  res.set("Access-Control-Allow-Origin", "*");

  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, X-Signature, X-Timestamp");
    return res.status(204).send("");
  }

  // Apenas aceita POST
  if (req.method !== "POST") {
    return res.status(405).json({error: "Method not allowed"});
  }

  try {
    // 1. Buscar Webhook Secret do Firestore
    const configDoc = await db.collection("AppInfo").doc("didio").get();

    if (!configDoc.exists) {
      console.error("Configuração do Didit não encontrada em AppInfo/didio");
      return res.status(500).json({error: "Configuration not found"});
    }

    const config = configDoc.data();
    const WEBHOOK_SECRET = config.webhook_secret;

    if (!WEBHOOK_SECRET) {
      console.error("Webhook secret não configurado em AppInfo/didio");
      return res.status(500).json({error: "Webhook secret not configured"});
    }

    // 2. Extrair headers de segurança
    const signature = req.get("X-Signature");
    const timestamp = req.get("X-Timestamp");

    if (!signature || !timestamp) {
      console.error("Headers de segurança ausentes");
      return res.status(401).json({error: "Missing security headers"});
    }

    // 3. Validar timestamp (máximo 5 minutos)
    const currentTime = Math.floor(Date.now() / 1000);
    const incomingTime = parseInt(timestamp, 10);

    if (Math.abs(currentTime - incomingTime) > 300) {
      console.error("Timestamp expirado:", {currentTime, incomingTime});
      return res.status(401).json({error: "Request timestamp is stale"});
    }

    // 4. Obter o body raw (já está em req.rawBody no Firebase Functions)
    // IMPORTANTE: Usar req.rawBody para garantir que a assinatura corresponda exatamente ao que foi enviado
    const rawBody = req.rawBody || JSON.stringify(req.body);

    // 5. Validar assinatura HMAC
    const hmac = crypto.createHmac("sha256", WEBHOOK_SECRET);
    const expectedSignature = hmac.update(rawBody).digest("hex");

    const expectedBuffer = Buffer.from(expectedSignature, "utf8");
    const providedBuffer = Buffer.from(signature, "utf8");

    if (
      expectedBuffer.length !== providedBuffer.length ||
      !crypto.timingSafeEqual(expectedBuffer, providedBuffer)
    ) {
      console.error("Assinatura inválida:", {
        expected: expectedSignature,
        provided: signature,
      });
      return res.status(401).json({error: "Invalid signature"});
    }

    // 6. Processar o webhook
    const webhookData = req.body;
    const {
      session_id,
      status,
      webhook_type,
      vendor_data,
      workflow_id,
      metadata,
      decision,
      created_at,
      timestamp: webhookTimestamp,
    } = webhookData;

    console.log("Webhook recebido:", {
      session_id,
      status,
      webhook_type,
      vendor_data,
    });

    // Verificar duplicidade (Idempotência)
    if (webhookTimestamp) {
      const existingWebhook = await db.collection("DiditWebhooks")
        .where("session_id", "==", session_id)
        .where("timestamp", "==", webhookTimestamp)
        .limit(1)
        .get();

      if (!existingWebhook.empty) {
        console.log("Webhook duplicado ignorado:", session_id, webhookTimestamp);
        return res.status(200).json({
          message: "Webhook already processed (duplicate)",
          session_id: session_id,
        });
      }
    }

    // 7. Salvar webhook no histórico (apenas se for status relevante)
    // Ignora status intermediários para evitar poluição do banco
    const relevantStatuses = ["Approved", "Rejected", "Failed", "In Review"];
    let docRef: any = null;

    if (relevantStatuses.includes(status)) {
      const webhookRecord: any = {
        session_id,
        status,
        webhook_type,
        vendor_data,
        received_at: admin.firestore.FieldValue.serverTimestamp(),
        processed: false,
      };

      // Adiciona apenas campos que não são undefined
      if (workflow_id !== undefined) webhookRecord.workflow_id = workflow_id;
      if (metadata !== undefined) webhookRecord.metadata = metadata;
      if (decision !== undefined) webhookRecord.decision = decision;
      if (created_at !== undefined) webhookRecord.created_at = created_at;
      if (webhookTimestamp !== undefined) webhookRecord.timestamp = webhookTimestamp;

      docRef = await db.collection("DiditWebhooks").add(webhookRecord);
    } else {
      console.log(`Webhook com status '${status}' não salvo em DiditWebhooks (ignorado)`);
    }

    // 8. Atualizar sessão no Firestore
    const sessionRef = db.collection("DiditSessions").doc(session_id);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      console.warn("Sessão não encontrada:", session_id);
      // Não retorna erro, webhook é válido mesmo se sessão não existir
    } else {
      const updateData: any = {
        status: status,
        lastWebhookType: webhook_type,
        lastWebhookAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Apenas marca como completedAt se for status final
      if (status === "Approved" || status === "Rejected" || status === "Failed") {
        updateData.completedAt = admin.firestore.FieldValue.serverTimestamp();
      }

      // Adiciona decision se existir
      if (decision !== undefined) {
        updateData.result = decision;
      }

      await sessionRef.update(updateData);

      console.log("Sessão atualizada:", session_id, "status:", status);
    }

    // 9. Se aprovado, salvar verificação
    if (status === "Approved" && decision && decision.id_verification) {
      const idVerification = decision.id_verification;
      const userId = vendor_data; // vendor_data é o userId

      if (userId && idVerification.status === "Approved") {
        try {
          // Salvar em FaceVerifications
          await db.collection("FaceVerifications").doc(userId).set({
            userId: userId,
            facialId: session_id,
            verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            status: "verified",
            gender: idVerification.gender || null,
            age: idVerification.age || null,
            details: {
              verification_type: "didit",
              verification_date: new Date().toISOString(),
              document_type: idVerification.document_type,
              document_number: idVerification.document_number,
              full_name: idVerification.full_name,
              first_name: idVerification.first_name,
              last_name: idVerification.last_name,
              date_of_birth: idVerification.date_of_birth,
              nationality: idVerification.nationality,
              issuing_state: idVerification.issuing_state_name,
              portrait_image: idVerification.portrait_image,
              session_id: session_id,
              session_url: decision.session_url,
            },
          });

          // Atualizar usuário
          await db.collection("Users").doc(userId).set({
            user_is_verified: true,
            verified_at: admin.firestore.FieldValue.serverTimestamp(),
            facial_id: session_id,
            verification_type: "didit",
          }, {merge: true});

          console.log("Verificação salva automaticamente para:", userId);
        } catch (error) {
          console.error("Erro ao salvar verificação:", error);
          // Não retorna erro, webhook foi processado com sucesso
        }
      }
    }

    // 10. Marcar webhook como processado (se foi salvo)
    if (docRef) {
      await docRef.update({processed: true});
    }

    // 11. Retornar sucesso
    return res.status(200).json({
      message: "Webhook processed successfully",
      session_id: session_id,
      status: status,
    });
  } catch (error) {
    console.error("Erro ao processar webhook:", error);
    return res.status(500).json({
      error: "Internal server error",
      message: (error as any).message,
    });
  }
});
