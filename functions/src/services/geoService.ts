/**
 * GEO SERVICE - Serviço de geolocalização para Cloud Functions
 *
 * Replica a lógica do GeoIndexService do Flutter para uso no backend.
 * Responsável por:
 * - Bounding box para queries otimizadas
 * - Cálculo de distância (Haversine)
 * - Busca de usuários em raio geográfico
 */

import * as admin from "firebase-admin";

const EARTH_RADIUS_KM = 6371.0;
const DEFAULT_RADIUS_KM = 30.0;

interface BoundingBox {
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
}

/** Coordenadas geográficas normalizadas (latitude/longitude). */
type UserCoordinates = {latitude: number; longitude: number};

/**
 * Converte um valor desconhecido para número finito (ou null).
 * @param {unknown} value - Valor de entrada
 * @return {number|null} Número finito ou null
 */
function asFiniteNumber(value: unknown): number | null {
  const num = typeof value === "number" ? value : null;
  return num != null && Number.isFinite(num) ? num : null;
}

/**
 * Extrai coordenadas do documento de usuário suportando schemas atual
 * e legado.
 * @param {FirebaseFirestore.DocumentData} data - Dados do documento
 * Users/{userId}
 * @return {UserCoordinates|null} Coordenadas ou null se ausentes
 */
function extractUserCoordinates(
  data: FirebaseFirestore.DocumentData
): UserCoordinates | null {
  // Schema atual do app (top-level)
  const topLat = asFiniteNumber(data.latitude);
  const topLng = asFiniteNumber(data.longitude);
  if (topLat != null && topLng != null) {
    return {latitude: topLat, longitude: topLng};
  }

  // Schema legado (lastLocation.{latitude,longitude})
  const legacyLat = asFiniteNumber(data.lastLocation?.latitude);
  const legacyLng = asFiniteNumber(data.lastLocation?.longitude);
  if (legacyLat != null && legacyLng != null) {
    return {latitude: legacyLat, longitude: legacyLng};
  }

  // Fallback: alguns documentos podem ter GeoPoint em `location`
  const geoPointLat = asFiniteNumber(data.location?.latitude);
  const geoPointLng = asFiniteNumber(data.location?.longitude);
  if (geoPointLat != null && geoPointLng != null) {
    return {latitude: geoPointLat, longitude: geoPointLng};
  }

  return null;
}

/**
 * Calcula bounding box para query inicial
 * @param {number} latitude - Latitude do centro
 * @param {number} longitude - Longitude do centro
 * @param {number} radiusKm - Raio em km
 * @return {BoundingBox} Limites do bounding box
 */
function calculateBoundingBox(
  latitude: number,
  longitude: number,
  radiusKm: number
): BoundingBox {
  const latDelta = radiusKm / 111.0; // ~111km por grau de latitude
  const lngDelta = radiusKm / (111.0 * Math.cos((latitude * Math.PI) / 180));

  return {
    minLat: latitude - latDelta,
    maxLat: latitude + latDelta,
    minLng: longitude - lngDelta,
    maxLng: longitude + lngDelta,
  };
}

/**
 * Calcula distância real usando fórmula de Haversine
 * @param {number} lat1 - Latitude do ponto 1
 * @param {number} lng1 - Longitude do ponto 1
 * @param {number} lat2 - Latitude do ponto 2
 * @param {number} lng2 - Longitude do ponto 2
 * @return {number} Distância em km
 */
function distanceKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_KM * c;
}

/**
 * Busca usuários dentro de um raio geográfico
 * @param {object} options - Opções de busca
 * @return {Promise<string[]>} Lista de IDs de usuários dentro do raio
 */
export async function findUsersInRadius(options: {
  latitude: number;
  longitude: number;
  radiusKm?: number;
  excludeUserIds?: string[];
  limit?: number;
}): Promise<string[]> {
  const {
    latitude,
    longitude,
    radiusKm = DEFAULT_RADIUS_KM,
    excludeUserIds = [],
    limit = 500,
  } = options;

  console.log("\n🌍 [GeoService] findUsersInRadius()");
  console.log(`   Centro: (${latitude}, ${longitude})`);
  console.log(`   Raio: ${radiusKm}km`);
  console.log(`   Excluir: ${excludeUserIds.length} IDs`);

  const excludeSet = new Set(excludeUserIds);
  const bounds = calculateBoundingBox(latitude, longitude, radiusKm);

  const firestore = admin.firestore();

  // A app grava coordenadas no topo (Users.latitude/longitude).
  // Mantemos fallback pro legado (Users.lastLocation.latitude/longitude)
  // durante migração.
  // Observação: o projeto tem regras para /Users e /users; suportamos ambos.
  const queryDefs = [
    {collection: "Users", fieldPath: "latitude", label: "Users.latitude"},
    {
      collection: "Users",
      fieldPath: "lastLocation.latitude",
      label: "Users.lastLocation.latitude",
    },
    {collection: "users", fieldPath: "latitude", label: "users.latitude"},
    {
      collection: "users",
      fieldPath: "lastLocation.latitude",
      label: "users.lastLocation.latitude",
    },
  ];

  const snapshots = await Promise.all(
    queryDefs.map((q) =>
      firestore
        .collection(q.collection)
        .where(q.fieldPath, ">=", bounds.minLat)
        .where(q.fieldPath, "<=", bounds.maxLat)
        .limit(limit)
        .get()
    )
  );

  const docsById = new Map<string, FirebaseFirestore.QueryDocumentSnapshot>();
  snapshots.forEach((snapshot) => {
    snapshot.docs.forEach((doc) => {
      if (!docsById.has(doc.id)) {
        docsById.set(doc.id, doc);
      }
    });
  });
  const counts = queryDefs
    .map((q, index) => `${q.label}:${snapshots[index].size}`)
    .join(", ");
  console.log(
    `📍 [GeoService] ${docsById.size} usuários no bounding box ` +
      `(${counts})`
  );

  if (docsById.size === 0) {
    console.log("⚠️ [GeoService] Nenhum usuário no bounding box");
    return [];
  }

  // Filtrar por distância real e longitude
  const usersInRadius: string[] = [];

  for (const doc of docsById.values()) {
    // Excluir IDs especificados
    if (excludeSet.has(doc.id)) {
      continue;
    }

    const data = doc.data();
    const coords = extractUserCoordinates(data);
    if (coords == null) {
      continue;
    }

    const userLat = coords.latitude;
    const userLng = coords.longitude;

    // Filtrar longitude (bounding box só filtra latitude)
    if (userLng < bounds.minLng || userLng > bounds.maxLng) {
      continue;
    }

    // Calcular distância real
    const distance = distanceKm(latitude, longitude, userLat, userLng);

    if (distance <= radiusKm) {
      usersInRadius.push(doc.id);

      if (usersInRadius.length >= limit) {
        break;
      }
    }
  }

  console.log(`✅ [GeoService] ${usersInRadius.length} usuários no raio`);
  return usersInRadius;
}

/**
 * Busca participantes de um evento (status approved/autoApproved)
 * @param {string} eventId - ID do evento
 * @return {Promise<string[]>} Lista de IDs dos participantes
 */
export async function getEventParticipants(
  eventId: string
): Promise<string[]> {
  const snapshot = await admin
    .firestore()
    .collection("EventApplications")
    .where("eventId", "==", eventId)
    .where("status", "in", ["approved", "autoApproved"])
    .get();

  if (snapshot.empty) {
    return [];
  }

  return snapshot.docs.map((doc) => doc.data().userId as string);
}
