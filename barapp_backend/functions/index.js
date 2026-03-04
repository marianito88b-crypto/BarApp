/**
 * IMPORTACIONES Y CONFIGURACIÓN
 */
const functions = require("firebase-functions/v1");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const admin = require("firebase-admin");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");

initializeApp();
const db = getFirestore();
const storage = getStorage();

// ==================================================================
// 1. FUNCIÓN DE CHAT (ACTUALIZADA A FCM V1)
// ==================================================================
exports.sendChatNotification = functions.firestore
  .document("chats/{chatId}/mensajes/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    const autorId = messageData.autorId;
    const textoMensaje = messageData.texto;
    const chatId = context.params.chatId;

    const parts = chatId.split("_");
    let receiverId = (parts[1] === autorId) ? parts[2] : parts[1];

    if (!receiverId) return null;

    // Verificación de bloqueo
    const blockSnap = await db.doc(`usuarios/${receiverId}/blockedUsers/${autorId}`).get();
    if (blockSnap.exists) {
        console.log(`🚫 Bloqueado: ${receiverId} bloqueó a ${autorId}`);
        return null;
    }

    const [receiverDoc, autorDoc] = await Promise.all([
      db.collection("usuarios").doc(receiverId).get(),
      db.collection("usuarios").doc(autorId).get()
    ]);

    if (!receiverDoc.exists || !autorDoc.exists) return null;

    const receiverData = receiverDoc.data();
    const autorData = autorDoc.data();
    const fcmToken = receiverData.fcmToken;
    const autorName = autorData.displayName || "Alguien";

    if (!fcmToken) return null;

    // Estructura moderna de mensaje (FCM v1 compatible)
    const message = {
      token: fcmToken,
      notification: {
        title: autorName,
        body: textoMensaje,
      },
      data: {
        type: "chat",
        id: autorId,
        extraName: autorName,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
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
    };

    try {
      await admin.messaging().send(message);
      console.log("✅ Notificación de chat enviada.");
    } catch (error) {
      if (error.code === "messaging/invalid-registration-token" ||
          error.code === "messaging/registration-token-not-registered") {
        await db.collection("usuarios").doc(receiverId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
          fcmTokenInvalidAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log("⚠️ FCM token inválido removido para usuario", receiverId);
      } else {
        console.error("❌ Error en FCM:", error);
      }
    }
  });

// ==================================================================
// 1b. NOTIFICACIÓN PUSH AL PREMIAR CLIENTE (Cupón de regalo)
// ==================================================================
// Dispara cuando se crea un cupón en mis_cupones (users o usuarios)
// Solo para cupones de premio (con venueId), no BarPoints
exports.sendGiftCouponNotification = functions.firestore
  .document("{col}/{userId}/mis_cupones/{cuponId}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (data.origenBarpoints === true) return null;

    const venueId = data.venueId || data.placeId;
    const venueName = data.venueName || data.placeName || "Un local";
    const descuento = data.descuentoPorcentaje ?? 10;

    if (!venueId || venueId === "") return null;

    const userId = context.params.userId;
    const col = context.params.col;

    let userDoc = await db.collection(col).doc(userId).get();
    if (!userDoc.exists && col === "users") {
      userDoc = await db.collection("usuarios").doc(userId).get();
    } else if (!userDoc.exists && col === "usuarios") {
      userDoc = await db.collection("users").doc(userId).get();
    }

    if (!userDoc.exists) return null;

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    const title = `¡${venueName} te ha premiado! 🎁`;
    const body = `Recibiste un ${Math.round(descuento)}% de descuento para tu próxima compra por ser un cliente destacado. ¡Aprovéchalo antes de que venza!`;

    const message = {
      token: fcmToken,
      notification: { title, body },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        screen: "my_gifts",
        type: "gift_coupon",
        placeId: venueId,
        venueName,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
    };

    try {
      await admin.messaging().send(message);
      console.log("✅ Notificación de cupón de regalo enviada a", userId);
    } catch (error) {
      if (error.code === "messaging/invalid-registration-token" ||
          error.code === "messaging/registration-token-not-registered") {
        await db.collection(col).doc(userId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
          fcmTokenInvalidAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log("⚠️ FCM token inválido removido para usuario", userId);
      } else {
        console.error("❌ Error FCM cupón regalo:", error);
      }
    }
    return null;
  });

// ==================================================================
// 1c. NOTIFICACIÓN REACCIÓN A POST (Muro)
// ==================================================================
// Dispara cuando se actualiza un post en comunidad y hay nueva reacción
function getAllReactionUserIds(reaccionesUsuarios) {
  if (!reaccionesUsuarios || typeof reaccionesUsuarios !== "object") return new Set();
  const uids = new Set();
  for (const list of Object.values(reaccionesUsuarios)) {
    if (Array.isArray(list)) list.forEach((uid) => uids.add(uid));
    else if (list && typeof list === "object") Object.values(list).forEach((uid) => uids.add(uid));
  }
  return uids;
}

exports.notifyPostReaction = functions.firestore
  .document("comunidad/{postId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    const oldUids = getAllReactionUserIds(before.reaccionesUsuarios);
    const newUids = getAllReactionUserIds(after.reaccionesUsuarios);

    const addedUids = [...newUids].filter((uid) => !oldUids.has(uid));
    if (addedUids.length === 0) return null;

    const authorId = after.authorId || "";
    const reactorId = addedUids[0];
    if (!authorId || authorId === reactorId) return null;

    let authorDoc = await db.collection("usuarios").doc(authorId).get();
    if (!authorDoc.exists) authorDoc = await db.collection("users").doc(authorId).get();
    if (!authorDoc.exists) return null;

    const fcmToken = authorDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    let reactorDoc = await db.collection("usuarios").doc(reactorId).get();
    if (!reactorDoc.exists) reactorDoc = await db.collection("users").doc(reactorId).get();
    const reactorName = reactorDoc.exists ? (reactorDoc.data()?.displayName || "Alguien") : "Alguien";

    const title = `¡A ${reactorName} le gustó tu post! ❤️`;

    const message = {
      token: fcmToken,
      notification: { title, body: "Mirá quién reaccionó en el muro" },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        screen: "community_wall",
        type: "post_reaction",
        postId: context.params.postId,
      },
      android: { priority: "high", notification: { channelId: "high_importance_channel", sound: "default" } },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    };

    try {
      await admin.messaging().send(message);
      console.log("✅ Notificación reacción post enviada a", authorId);
    } catch (error) {
      if (error.code === "messaging/invalid-registration-token" || error.code === "messaging/registration-token-not-registered") {
        await (authorDoc.ref).update({ fcmToken: admin.firestore.FieldValue.delete() });
      }
    }
    return null;
  });

// ==================================================================
// 1d. NOTIFICACIÓN REACCIÓN A HISTORIA
// ==================================================================
exports.notifyStoryReaction = functions.firestore
  .document("stories/{storyId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    const oldUsers = before.reactionsUsers || {};
    const newUsers = after.reactionsUsers || {};
    const oldUids = new Set(Object.keys(oldUsers));
    const newUids = new Set(Object.keys(newUsers));
    const addedUids = [...newUids].filter((uid) => !oldUids.has(uid));
    if (addedUids.length === 0) return null;

    const authorId = after.authorId || "";
    const reactorId = addedUids[0];
    if (!authorId || authorId === reactorId) return null;

    let authorDoc = await db.collection("usuarios").doc(authorId).get();
    if (!authorDoc.exists) authorDoc = await db.collection("users").doc(authorId).get();
    if (!authorDoc.exists) return null;

    const fcmToken = authorDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    let reactorDoc = await db.collection("usuarios").doc(reactorId).get();
    if (!reactorDoc.exists) reactorDoc = await db.collection("users").doc(reactorId).get();
    const reactorName = reactorDoc.exists ? (reactorDoc.data()?.displayName || "Alguien") : "Alguien";

    const title = `¡${reactorName} reaccionó a tu historia! 🔥`;

    const message = {
      token: fcmToken,
      notification: { title, body: "Mirá la reacción" },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        screen: "story_viewer",
        type: "story_reaction",
        storyId: context.params.storyId,
      },
      android: { priority: "high", notification: { channelId: "high_importance_channel", sound: "default" } },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    };

    try {
      await admin.messaging().send(message);
      console.log("✅ Notificación reacción historia enviada a", authorId);
    } catch (error) {
      if (error.code === "messaging/invalid-registration-token" || error.code === "messaging/registration-token-not-registered") {
        await (authorDoc.ref).update({ fcmToken: admin.firestore.FieldValue.delete() });
      }
    }
    return null;
  });

// ==================================================================
// 2. MONITOR DE RESERVAS (NUEVA - TOLERANCIA 15 MIN)
// ==================================================================
// Corre cada 5 min para ser quirúrgicos con el tiempo del bar
exports.autoManageReservations = onSchedule(
  {
    schedule: "every 5 minutes",
    region: "southamerica-east1",
    memory: "256MiB",
  },
  async (event) => {
    const now = admin.firestore.Timestamp.now();
    // Tolerancia de 15 minutos para considerar "Ausente"
    const toleranceTime = new Date(now.toDate().getTime() - 15 * 60000);

    try {
      const snapshot = await db.collectionGroup("reservas")
        .where("estado", "==", "confirmada")
        .where("fecha", "<=", now)
        .get();

      if (snapshot.empty) return;

      const batch = db.batch();
      let count = 0;

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const fechaReserva = data.fecha.toDate();

        // Si pasó el tiempo de reserva + 15 min de gracia
        if (fechaReserva < toleranceTime) {
          // 1. Marcar como ausente
          batch.update(doc.ref, { estado: "no_asistio" });
          
          // 2. Liberar la mesa asociada en el local correspondiente
          if (data.mesaId) {
             const mesaRef = doc.ref.parent.parent.collection("mesas").doc(data.mesaId);
             batch.update(mesaRef, { 
               estado: "libre", 
               reservaIdActiva: admin.firestore.FieldValue.delete(),
               clienteActivo: admin.firestore.FieldValue.delete()
             });
          }
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
        console.log(`✅ ${count} reservas vencidas pasaron a "no_asistio" y mesas liberadas.`);
      }
    } catch (e) {
      console.error("❌ Error en autoManageReservations:", e);
    }
  }
);

// ==================================================================
// 3. RATING PROMEDIO (Gen 2)
// ==================================================================
exports.updatePlaceAverageRating = onDocumentWritten(
  { region: "southamerica-east1" },
  "places/{placeId}/ratings/{ratingId}",
  async (event) => {
    const placeId = event.params.placeId;
    const ratingsRef = db.collection(`places/${placeId}/ratings`);
    const snapshot = await ratingsRef.get();

    if (snapshot.empty) {
      await db.doc(`places/${placeId}`).update({ averageRating: 0, ratingsCount: 0 });
      return;
    }

    let total = 0;
    snapshot.forEach(doc => total += (doc.data().rating || 0));
    const avg = total / snapshot.size;

    await db.doc(`places/${placeId}`).update({
      averageRating: parseFloat(avg.toFixed(1)),
      ratingsCount: snapshot.size,
    });
  }
);

// ==================================================================
// 4. STOCK GLOBAL (TODOS LOS CANALES) — ULTRASENIOR
// ==================================================================
exports.handleGlobalOrderStock = functions.firestore
  .document("places/{placeId}/orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const items = order.items || [];
    const placeId = context.params.placeId;
    const orderRef = snap.ref;

    // 🛑 Guardia absoluta: Si no hay items, no hacemos nada
    if (!items.length) return null;

    // 🔥🔥🔥 NUEVA CONDICIÓN: IGNORAR PEDIDOS DE SALÓN 🔥🔥🔥
    // La App (Flutter) ya realizó la transacción de stock localmente.
    // Si la función corre también, descontaríamos el stock dos veces.
    if (order.origen === 'salon') {
      console.log(`⏩ Pedido ${context.params.orderId} de SALÓN detectado. Omitiendo lógica Cloud.`);
      return null;
    }

    // 🛑 Si el estado no es pendiente, tampoco hacemos nada
    if (order.estado && order.estado !== "pendiente") return null;

    try {
      await db.runTransaction(async (tx) => {

        // 🔁 Releer el pedido dentro de la transacción
        const freshOrderSnap = await tx.get(orderRef);
        const freshOrder = freshOrderSnap.data();

        // 🛑 Anti doble ejecución
        if (freshOrder.estado && freshOrder.estado !== "pendiente") {
          return;
        }

        // 1️⃣ VALIDACIÓN DE STOCK (SOLO controlaStock === true)
        for (const item of items) {
          if (item.controlaStock !== true) continue;

          if (!item.productoId) {
            tx.update(orderRef, {
              estado: "error",
              errorStock: `Item inválido (sin productoId): ${item.nombre || "sin nombre"}`,
            });
            return;
          }

          const productRef = db
            .collection("places")
            .doc(placeId)
            .collection("menu")
            .doc(item.productoId);

          const productSnap = await tx.get(productRef);

          if (!productSnap.exists) {
            tx.update(orderRef, {
              estado: "rechazado",
              errorStock: `Producto inexistente: ${item.nombre}`,
            });
            return;
          }

          const stockActual = productSnap.data().stock ?? 0;

          if (stockActual < item.cantidad) {
            tx.update(orderRef, {
              estado: "rechazado",
              errorStock: `Stock insuficiente de "${item.nombre}". Quedan ${stockActual}.`,
            });
            return;
          }
        }

        // 2️⃣ DESCUENTO ATÓMICO
        for (const item of items) {
          if (item.controlaStock !== true) continue;

          const productRef = db
            .collection("places")
            .doc(placeId)
            .collection("menu")
            .doc(item.productoId);

          tx.update(productRef, {
            stock: admin.firestore.FieldValue.increment(-item.cantidad),
          });
        }

        // 3️⃣ RESERVA SILENCIOSA (MODIFICADO PARA MEJOR UX)
        // Ya no cambiamos a "confirmado" automáticamente.
        // Solo marcamos que el stock ya fue reservado.
        tx.update(orderRef, {
          // estado: "confirmado", // <--- COMENTADO: Esperamos confirmación manual del dueño
          stockReservado: true,    // 🚩 Bandera para saber que ya descontamos
          procesadoStockAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      console.log(`✅ Stock descontado (Reserva Silenciosa) para pedido ${context.params.orderId}.`);
      return null;

    } catch (error) {
      console.error("❌ Error crítico en handleGlobalOrderStock:", error);

      await orderRef.update({
        estado: "error",
        errorStock: "Error interno al procesar stock. Intentar nuevamente.",
      });

      return null;
    }
  });

// ==================================================================
// 5. ALERTA DE STOCK CRÍTICO
// ==================================================================
exports.notifyCriticalStock = functions.firestore
  .document("places/{placeId}/menu/{productId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    if (newData.controlaStock && newData.stock < 5 && oldData.stock >= 5) {
      const placeDoc = await db.doc(`places/${context.params.placeId}`).get();
      const ownerId = placeDoc.data()?.ownerId;
      if (!ownerId) return null;

      const ownerDoc = await db.doc(`usuarios/${ownerId}`).get();
      const fcmToken = ownerDoc.data()?.fcmToken;

      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: { title: "⚠️ ¡STOCK CRÍTICO!", body: `Quedan solo ${newData.stock} de "${newData.nombre}".` },
          data: { type: "stock_alert", placeId: context.params.placeId }
        });
      }
    }
    return null;
  });

// ==================================================================
// 6. LIMPIEZA DE HISTORIAS (ROBUSTA)
// ==================================================================
exports.cleanOldStories = onSchedule(
  {
    schedule: "every 60 minutes",
    region: "southamerica-east1",
    timeoutSeconds: 540, // 9 min de tiempo límite
    memory: "512MiB",    // Más memoria para el procesamiento de archivos
  },
  async (event) => {
    const now = new Date();
    try {
      const snapshot = await db.collection("stories").where("expiresAt", "<=", now).limit(100).get();
      if (snapshot.empty) return;

      const bucket = storage.bucket();
      const tasks = snapshot.docs.map(async (doc) => {
        const mediaUrl = doc.data().mediaUrl;
        if (mediaUrl) {
          const filePath = extractFilePathFromUrl(mediaUrl);
          if (filePath) await bucket.file(filePath).delete().catch(e => console.error("Err Storage:", e));
        }
        return doc.ref.delete();
      });

      await Promise.all(tasks);
      console.log("✅ Limpieza de historias finalizada.");
    } catch (e) {
      console.error("Error en cleanOldStories:", e);
    }
  }
);

// ==================================================================
// 7. NOTIFICACIONES DE EVENTOS (FLEXIBLE & PRO)
// ==================================================================
exports.sendEventNotification = functions.firestore
  .document("events/{eventId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const placeId = data.placeId;
    const notificationType = data.notificationType || "global";
    const now = admin.firestore.Timestamp.now();

    const placeDoc = await db.doc(`places/${placeId}`).get();
    if (!placeDoc.exists) return null;

    const placeData = placeDoc.data();
    const plan = placeData.plan || "basic";

    // 1️⃣ DEFINICIÓN DE LÍMITES (LÓGICA JERÁRQUICA)
    // A. Límites por defecto del Plan
    let defaultLimit = (notificationType === "followers") ? 1 : (plan === "basic_plus" ? 2 : 1);
    
    // B. Límites Custom (Si existen en el documento del bar, ganan)
    // Estructura en Firebase: places/{id} -> customLimits: { global: 5, followers: 10 }
    const customLimits = placeData.customLimits || {};
    
    // 🔥 EL LÍMITE FINAL ES EL CUSTOM (SI EXISTE) O EL DEFAULT
    let finalLimit = (customLimits[notificationType] !== undefined) 
        ? customLimits[notificationType] 
        : defaultLimit;

    // Defino periodo
    let periodType = (notificationType === "followers") ? "day" : "week";

    // Chequeo de uso actual
    const limitRef = db.collection("notification_limits").doc(`${placeId}_${notificationType}`);
    const limitSnap = await limitRef.get();

    let count = limitSnap.exists ? limitSnap.data().count : 0;
    let periodStart = limitSnap.exists ? limitSnap.data().periodStart : now;

    // Chequeo de tiempo (reseteo diario o semanal)
    const isNew = periodType === "day" 
        ? isDifferentDay(periodStart.toDate(), now.toDate()) 
        : isDifferentWeek(periodStart.toDate(), now.toDate());

    // 🛑 GUARDIA: Si no es nuevo periodo Y ya gastó su límite
    if (!isNew && count >= finalLimit) {
        console.log(`🚫 Límite alcanzado para ${placeId} (${notificationType}). Usados: ${count}/${finalLimit}`);
        return null;
    }

    // ✅ ENVIAR
    await admin.messaging().send({
      topic: notificationType === "global" ? "events" : `followers_${placeId}`,
      notification: { title: data.placeName || "¡Nuevo Evento!", body: data.title },
      data: { type: "event", placeId, eventId: context.params.eventId }
    });

    // Actualizar contador
    await limitRef.set({
      placeId, type: notificationType, count: isNew ? 1 : count + 1,
      periodStart: isNew ? now : periodStart, updatedAt: now
    }, { merge: true });

    return null;
  });

// ==================================================================
// 7b. ACREDITACIÓN DE BARPOINTS AL ENTREGAR PEDIDO (SERVIDOR - MÁXIMA SEGURIDAD)
// ==================================================================
// Dispara cuando un pedido pasa a estado 'entregado'. Usa Admin SDK para:
// - Sumar barPoints al usuario de forma atómica
// - Marcar puntosAcreditados: true (idempotencia)
// - Crear entrada en historial_puntos
// Los usuarios NO pueden modificar barPoints desde el cliente (reglas Firestore).
const MAX_BAR_POINTS = 500;

function roundMoneda(val) {
  return Math.round(val * 100) / 100;
}

exports.onOrderDelivered = functions.firestore
  .document("places/{placeId}/orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Solo actuar cuando el estado pasa a 'entregado'
    if (after.estado !== "entregado" || before.estado === "entregado") {
      return null;
    }

    const puntosAcreditados = after.puntosAcreditados === true;
    if (puntosAcreditados) {
      console.log(`⏩ Pedido ${context.params.orderId} ya tenía puntos acreditados. Idempotente.`);
      return null;
    }

    const puntosEstimados = Math.floor(Number(after.puntosEstimados) || 0);
    const userId = after.userId;
    const placeId = context.params.placeId;
    const orderId = context.params.orderId;

    if (!userId || typeof userId !== "string" || userId.trim() === "" || puntosEstimados <= 0) {
      return null;
    }

    try {
      await db.runTransaction(async (tx) => {
        const orderRef = change.after.ref;

        // Releer pedido dentro de la transacción (verificación atómica)
        const orderSnap = await tx.get(orderRef);
        const orderData = orderSnap.data();
        if (!orderSnap.exists || orderData.puntosAcreditados === true) {
          throw new Error("Pedido ya procesado o no existe");
        }

        // Resolver usuario en usuarios o users
        let userRef = db.collection("usuarios").doc(userId);
        let userSnap = await tx.get(userRef);
        if (!userSnap.exists) {
          userRef = db.collection("users").doc(userId);
          userSnap = await tx.get(userRef);
        }
        if (!userSnap.exists) {
          throw new Error("Usuario no encontrado");
        }

        const puntosActuales = Math.floor(Number(userSnap.data().barPoints) || 0);
        const nuevosPuntos = Math.min(puntosActuales + puntosEstimados, MAX_BAR_POINTS);
        const puntosFinales = Math.round(roundMoneda(nuevosPuntos));

        // Nombre del lugar
        let placeNombre = "Local";
        try {
          const placeSnap = await tx.get(db.doc(`places/${placeId}`));
          if (placeSnap.exists) {
            placeNombre = placeSnap.data().nombre || "Local";
          }
        } catch (_) {}

        const concepto = `Compra en ${placeNombre}`;

        // 1. Actualizar barPoints del usuario (Admin SDK, bypassa reglas)
        tx.update(userRef, { barPoints: puntosFinales });

        // 2. Marcar pedido como puntos acreditados
        tx.update(orderRef, {
          puntosAcreditados: true,
          puntosAcreditadosAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 3. Crear entrada en historial_puntos
        tx.set(userRef.collection("historial_puntos").doc(), {
          concepto,
          monto: puntosEstimados,
          fecha: admin.firestore.FieldValue.serverTimestamp(),
          orderId,
          placeId,
        });
      });

      console.log(`✅ BarPoints acreditados: +${puntosEstimados} al usuario ${userId} (pedido ${orderId})`);
    } catch (error) {
      console.error("❌ Error acreditando BarPoints:", error);
    }
    return null;
  });

// ==================================================================
// 8. DEVOLUCIÓN DE STOCK AL RECHAZAR/CANCELAR (NUEVA)
// ==================================================================
exports.restoreStockOnCancel = onDocumentWritten(
  { region: "southamerica-east1" },
  "places/{placeId}/orders/{orderId}",
  async (event) => {
    // Si el documento se borró, no hacemos nada
    if (!event.data.after.exists) return null;

    const newData = event.data.after.data();
    const oldData = event.data.before.data();
    const placeId = event.params.placeId;

    // CONDICIÓN: El estado cambió a "rechazado" Y antes no lo estaba
    const pasoARechazado = newData.estado === "rechazado" && oldData?.estado !== "rechazado";

    // CONDICIÓN: El stock había sido reservado previamente
    // (Chequeamos la bandera que pusimos en la función anterior o si venía de un estado válido)
    const stockEstabaReservado = newData.stockReservado === true || 
                                 ["pendiente", "confirmado", "en_preparacion"].includes(oldData?.estado);

    if (pasoARechazado && stockEstabaReservado) {
      console.log(`🔄 Devolviendo stock para pedido rechazado: ${event.params.orderId}`);
      
      const items = newData.items || [];
      const batch = db.batch();
      let restoreCount = 0;

      for (const item of items) {
        if (item.controlaStock === true && item.productoId) {
            const productRef = db.doc(`places/${placeId}/menu/${item.productoId}`);
            // Incrementamos el stock (Devolución)
            batch.update(productRef, {
                stock: admin.firestore.FieldValue.increment(item.cantidad)
            });
            restoreCount++;
        }
      }

      if (restoreCount > 0) {
          // Quitamos la marca de stockReservado para no devolverlo dos veces si pasa algo raro
          batch.update(event.data.after.ref, { stockReservado: false, stockRestauradoAt: admin.firestore.FieldValue.serverTimestamp() });
          await batch.commit();
          console.log(`✅ Stock restaurado de ${restoreCount} items.`);
      }
    }
    return null;
  }
);


// HELPERS
function extractFilePathFromUrl(urlStr) {
  try {
    const path = new URL(urlStr).pathname;
    const parts = path.split("/o/");
    return parts.length < 2 ? null : decodeURIComponent(parts[1].split("?")[0]);
  } catch (e) { return null; }
}

function isDifferentDay(a, b) { return a.toDateString() !== b.toDateString(); }
function isDifferentWeek(a, b) {
  const getWeek = (d) => {
    const date = new Date(d.getTime());
    date.setHours(0, 0, 0, 0);
    date.setDate(date.getDate() + 3 - (date.getDay() + 6) % 7);
    const week1 = new Date(date.getFullYear(), 0, 4);
    return 1 + Math.round(((date.getTime() - week1.getTime()) / 86400000 - 3 + (week1.getDay() + 6) % 7) / 7);
  };
  return getWeek(a) !== getWeek(b) || a.getFullYear() !== b.getFullYear();
}