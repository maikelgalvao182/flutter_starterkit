import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Webhook do FACEIO para sincronização em tempo real
 *
 * Recebe notificações sobre:
 * - Novo enrollment (cadastro facial)
 * - Autenticação bem-sucedida
 * - Exclusão de Facial ID
 * - Outros eventos do FACEIO
 *
 * @see https://faceio.net/webhooks-guide
 */

// Token de autenticação do FACEIO (Bearer token fixo)
const FACEIO_BEARER_TOKEN = "8651216558ceb13d27621a64f1d4ecf5";

// Tipos de eventos do FACEIO
enum FaceIOEventType {
  NEW_ENROLLMENT = "new_enrollment",
  AUTH_SUCCESS = "auth_success",
  FACIAL_ID_DELETED = "facial_id_deleted",
  AUTH_FAILED = "auth_failed",
  ENROLLMENT_FAILED = "enrollment_failed",
}

// Interface do payload do webhook
interface FaceIOWebhookPayload {
  event: FaceIOEventType;
  facialId: string;
  timestamp: number;
  userId?: string;
  gender?: "male" | "female";
  age?: number;
  ip?: string;
  userAgent?: string;
  reason?: string;
  details?: Record<string, unknown>;
}

/**
 * Verifica autenticidade do request do FACEIO
 * @param {functions.https.Request} req - Request HTTP
 * @return {boolean} True se válido
 */
function validateFaceIORequest(req: functions.https.Request): boolean {
  const authHeader = req.headers["www-authenticate"] as string;

  if (!authHeader) {
    console.error("❌ FACEIO Webhook: WWW-Authenticate header ausente");
    return false;
  }

  const expectedBearer = `Bearer ${FACEIO_BEARER_TOKEN}`;

  if (authHeader !== expectedBearer) {
    console.error("❌ FACEIO Webhook: Bearer token inválido");
    console.error(`   Recebido: ${authHeader}`);
    console.error(`   Esperado: ${expectedBearer}`);
    return false;
  }

  return true;
}

/**
 * Processa novo enrollment (cadastro facial)
 * @param {FaceIOWebhookPayload} payload - Dados do webhook
 * @return {Promise<void>}
 */
async function handleNewEnrollment(
  payload: FaceIOWebhookPayload
): Promise<void> {
  const {facialId, userId, gender, age, timestamp, ip} = payload;

  console.log(`✅ Novo enrollment: facialId=${facialId}, userId=${userId}`);

  if (!userId) {
    console.warn("⚠️ Enrollment sem userId associado");
    return;
  }

  const db = admin.firestore();
  const batch = db.batch();

  try {
    // 1. Atualizar documento de verificação do usuário
    const verificationRef = db.collection("FaceVerifications").doc(userId);
    batch.set(verificationRef, {
      userId,
      facialId,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "verified",
      gender: gender || null,
      age: age || null,
      details: {
        enrollmentTimestamp: timestamp,
        enrollmentIp: ip || null,
        source: "webhook",
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    // 2. Marcar usuário como verificado
    const userRef = db.collection("Users").doc(userId);
    batch.set(userRef, {
      user_is_verified: true,
      facial_verification: {
        facialId,
        verifiedAt: admin.firestore.Timestamp.fromMillis(timestamp),
        status: "verified",
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    // 3. Registrar log do evento
    const logRef = db.collection("FaceVerificationLogs").doc();
    batch.set(logRef, {
      eventType: FaceIOEventType.NEW_ENROLLMENT,
      userId,
      facialId,
      timestamp: admin.firestore.Timestamp.fromMillis(timestamp),
      metadata: {
        gender,
        age,
        ip,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();
    console.log(`✅ Enrollment processado: ${userId}`);
  } catch (error) {
    console.error("❌ Erro ao processar enrollment:", error);
    throw error;
  }
}

/**
 * Processa autenticação bem-sucedida
 * @param {FaceIOWebhookPayload} payload - Dados do webhook
 * @return {Promise<void>}
 */
async function handleAuthSuccess(
  payload: FaceIOWebhookPayload
): Promise<void> {
  const {facialId, userId, timestamp, ip} = payload;

  console.log(`✅ Auth success: facialId=${facialId}, userId=${userId}`);

  if (!userId) {
    console.warn("⚠️ Autenticação sem userId associado");
    return;
  }

  const db = admin.firestore();

  try {
    // Registrar log de autenticação
    await db.collection("FaceVerificationLogs").add({
      eventType: FaceIOEventType.AUTH_SUCCESS,
      userId,
      facialId,
      timestamp: admin.firestore.Timestamp.fromMillis(timestamp),
      metadata: {
        ip,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Atualizar última autenticação no perfil do usuário
    await db.collection("Users").doc(userId).update({
      "facial_verification.lastAuthAt":
        admin.firestore.Timestamp.fromMillis(timestamp),
      "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Auth success processado: ${userId}`);
  } catch (error) {
    console.error("❌ Erro ao processar auth success:", error);
    throw error;
  }
}

/**
 * Processa exclusão de Facial ID
 * @param {FaceIOWebhookPayload} payload - Dados do webhook
 * @return {Promise<void>}
 */
async function handleFacialIdDeleted(
  payload: FaceIOWebhookPayload
): Promise<void> {
  const {facialId, userId, timestamp, reason} = payload;

  console.log(`🗑️ Facial ID deleted: facialId=${facialId}, userId=${userId}`);

  if (!userId) {
    // Buscar userId pelo facialId
    const db = admin.firestore();
    const verificationSnapshot = await db.collection("FaceVerifications")
      .where("facialId", "==", facialId)
      .limit(1)
      .get();

    if (verificationSnapshot.empty) {
      console.warn("⚠️ Facial ID deletado não encontrado no sistema");
      return;
    }

    const verificationData = verificationSnapshot.docs[0].data();
    await handleFacialIdDeletedForUser(
      verificationData.userId,
      facialId,
      timestamp,
      reason
    );
  } else {
    await handleFacialIdDeletedForUser(userId, facialId, timestamp, reason);
  }
}

/**
 * Processa exclusão para usuário específico
 * @param {string} userId - ID do usuário
 * @param {string} facialId - ID facial
 * @param {number} timestamp - Timestamp
 * @param {string | undefined} reason - Motivo
 * @return {Promise<void>}
 */
async function handleFacialIdDeletedForUser(
  userId: string,
  facialId: string,
  timestamp: number,
  reason?: string
): Promise<void> {
  const db = admin.firestore();
  const batch = db.batch();

  try {
    // 1. Atualizar verificação como deletada
    const verificationRef = db.collection("FaceVerifications").doc(userId);
    batch.update(verificationRef, {
      status: "deleted",
      deletedAt: admin.firestore.Timestamp.fromMillis(timestamp),
      deleteReason: reason || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 2. Remover verificação do perfil do usuário
    const userRef = db.collection("Users").doc(userId);
    batch.update(userRef, {
      user_is_verified: false,
      facial_verification: admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 3. Registrar log
    const logRef = db.collection("FaceVerificationLogs").doc();
    batch.set(logRef, {
      eventType: FaceIOEventType.FACIAL_ID_DELETED,
      userId,
      facialId,
      timestamp: admin.firestore.Timestamp.fromMillis(timestamp),
      metadata: {
        reason,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();
    console.log(`✅ Facial ID deletion processado: ${userId}`);
  } catch (error) {
    console.error("❌ Erro ao processar facial ID deletion:", error);
    throw error;
  }
}

/**
 * Processa falha de autenticação
 * @param {FaceIOWebhookPayload} payload - Dados do webhook
 * @return {Promise<void>}
 */
async function handleAuthFailed(
  payload: FaceIOWebhookPayload
): Promise<void> {
  const {facialId, userId, timestamp, reason, ip} = payload;

  console.log(`❌ Auth failed: facialId=${facialId}, reason=${reason}`);

  const db = admin.firestore();

  try {
    await db.collection("FaceVerificationLogs").add({
      eventType: FaceIOEventType.AUTH_FAILED,
      userId: userId || null,
      facialId: facialId || null,
      timestamp: admin.firestore.Timestamp.fromMillis(timestamp),
      metadata: {
        reason,
        ip,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("✅ Auth failed log registrado");
  } catch (error) {
    console.error("❌ Erro ao registrar auth failed:", error);
  }
}

/**
 * Processa falha de enrollment
 * @param {FaceIOWebhookPayload} payload - Dados do webhook
 * @return {Promise<void>}
 */
async function handleEnrollmentFailed(
  payload: FaceIOWebhookPayload
): Promise<void> {
  const {userId, timestamp, reason, ip} = payload;

  console.log(`❌ Enrollment failed: userId=${userId}, reason=${reason}`);

  const db = admin.firestore();

  try {
    await db.collection("FaceVerificationLogs").add({
      eventType: FaceIOEventType.ENROLLMENT_FAILED,
      userId: userId || null,
      facialId: null,
      timestamp: admin.firestore.Timestamp.fromMillis(timestamp),
      metadata: {
        reason,
        ip,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("✅ Enrollment failed log registrado");
  } catch (error) {
    console.error("❌ Erro ao registrar enrollment failed:", error);
  }
}

/**
 * Cloud Function HTTP para receber webhooks do FACEIO
 */
export const faceioWebhook = functions
  .region("us-central1")
  .runWith({
    timeoutSeconds: 5,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    // Permitir apenas POST
    if (req.method !== "POST") {
      console.warn(
        `⚠️ FACEIO Webhook: Método ${req.method} não permitido`
      );
      res.status(405).send("Method Not Allowed");
      return;
    }

    // Validar autenticidade do request
    if (!validateFaceIORequest(req)) {
      res.status(401).send("Unauthorized");
      return;
    }

    // Validar Content-Type
    const contentType = req.headers["content-type"];
    if (!contentType || !contentType.includes("application/json")) {
      console.error(
        "❌ FACEIO Webhook: Content-Type deve ser application/json"
      );
      res.status(400).send("Invalid Content-Type");
      return;
    }

    try {
      const payload = req.body as FaceIOWebhookPayload;

      // Validar payload
      if (!payload.event || !payload.timestamp) {
        console.error("❌ FACEIO Webhook: Payload inválido", payload);
        res.status(400).send("Invalid payload");
        return;
      }

      console.log(`📥 FACEIO Webhook recebido: ${payload.event}`);

      // Processar evento
      switch (payload.event) {
      case FaceIOEventType.NEW_ENROLLMENT:
        await handleNewEnrollment(payload);
        break;

      case FaceIOEventType.AUTH_SUCCESS:
        await handleAuthSuccess(payload);
        break;

      case FaceIOEventType.FACIAL_ID_DELETED:
        await handleFacialIdDeleted(payload);
        break;

      case FaceIOEventType.AUTH_FAILED:
        await handleAuthFailed(payload);
        break;

      case FaceIOEventType.ENROLLMENT_FAILED:
        await handleEnrollmentFailed(payload);
        break;

      default:
        console.warn(`⚠️ Evento não reconhecido: ${payload.event}`);
        res.status(200).send("Event ignored");
        return;
      }

      // Responder em menos de 6 segundos (timeout do FACEIO)
      res.status(200).json({
        success: true,
        message: "Webhook processed successfully",
        event: payload.event,
        timestamp: Date.now(),
      });

      console.log(`✅ FACEIO Webhook processado: ${payload.event}`);
    } catch (error) {
      console.error("❌ Erro ao processar FACEIO webhook:", error);
      res.status(500).send("Internal Server Error");
    }
  });
