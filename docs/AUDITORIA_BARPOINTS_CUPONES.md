# Auditoría de Seguridad: BarPoints y Cupones

**Fecha:** Febrero 2025  
**Alcance:** `barpoints_service.dart`, `coupons_service.dart`, `checkout_logic.dart`, reglas Firestore

---

## Resumen Ejecutivo

Se realizó una auditoría técnica de grado senior sobre el sistema de BarPoints y Cupones. Se identificaron y corrigieron **vulnerabilidades críticas** relacionadas con doble gasto, consistencia transaccional y redondeo. Las correcciones implementadas elevan el nivel de seguridad a producción.

---

## Vulnerabilidades Identificadas y Correcciones

### 1. Doble Gasto de BarPoints (canjearPuntos) ✅ CORREGIDO

**Problema:** El canje de puntos usaba lecturas y escrituras separadas (batch sin transacción). Dos solicitudes simultáneas podían leer el mismo saldo, ambas aprobar el canje y crear dos cupones con los puntos de uno solo.

**Solución:** Se refactorizó `canjearPuntos` para usar `runTransaction` de Firestore. La lectura del saldo, la actualización de puntos, la creación del cupón y el registro en historial ocurren dentro de una única transacción atómica.

### 2. Doble Gasto de Cupones en Checkout ✅ CORREGIDO

**Problema:** El flujo era: crear pedido → después, en pasos separados, marcar cupón usado y registrar uso. Si la red fallaba entre el pedido y el registro, el cupón quedaba sin marcar y podía reutilizarse. Además, dos pestañas/dispositivos podían enviar pedidos casi simultáneamente y ambos pasar la validación antes de que ninguno marcara el cupón.

**Solución:** Se implementó `_submitOrderWithCuponAtomically`, que en una sola transacción:
- Verifica que el cupón existe y no está usado
- Crea el pedido
- Marca el cupón como usado
- Registra el uso en `cupones_usados`

Todo o nada. Si algo falla, nada se confirma.

### 3. Acreditación de Puntos (acreditarPuntos) ✅ CORREGIDO

**Problema:** Lectura del pedido y del usuario fuera de la transacción; posibles condiciones de carrera si dos entregas se procesaban casi al mismo tiempo.

**Solución:** `acreditarPuntos` ahora usa `runTransaction` para leer pedido y usuario, verificar `puntosAcreditados` y realizar todas las escrituras de forma atómica.

### 4. Validación de Saldo en Servidor ✅ GARANTIZADO

Todas las operaciones que modifican saldos (canje, acreditación) leen el estado actual **dentro** de la transacción. El valor en memoria no se usa para decisiones críticas; siempre se verifica contra Firestore.

### 5. Exclusividad de Venue (venueId) ✅ REFORZADO

**Problema potencial:** Cupones de regalo deben ser válidos solo en el bar que los emitió. La validación ya existía en `validarYCodigoCupon`.

**Refuerzo:** Se añadió validación adicional en `_submitOrderWithCuponAtomically` (defense in depth): antes de crear el pedido, se verifica que `venueId`/`placeId` del cupón coincida con el `placeId` del pedido.

### 6. Redondeo de Montos ✅ CORREGIDO

**Problema:** Cálculos con decimales flotantes podían generar valores con muchos decimales, provocando errores en pasarelas de pago o cierre de caja.

**Solución:** Se añadió `_redondearMoneda(value)` que redondea a 2 decimales (`(value * 100).round() / 100`). Se aplica a total, subtotal, descuento y costo de envío antes de persistir. También en el cálculo del descuento al aplicar el cupón.

### 7. codigoYaUsado - Fail-Closed ✅ CORREGIDO

**Problema:** Ante error de red o Firestore, se retornaba `false` (código no usado), permitiendo posible reutilización por fallback inseguro.

**Solución:** Ante error se retorna `true` (considerar código como usado). Política fail-closed: en duda, rechazar.

---

## Reglas de Firestore – Observaciones

### Permisos de Escritura

- **usuarios/{userId}:** `allow write: if isOwner(userId) || isSuperAdmin()`
  - Solo el propio usuario o SuperAdmin pueden escribir.
  - **Impacto:** `BarPointsService.acreditarPuntos` se ejecuta desde el panel del bar (dueño/repartidor). Ese usuario intenta actualizar `usuarios/{customerId}`. Como `request.auth.uid != customerId`, la escritura sería **rechazada** por las reglas actuales.
  - **Recomendación:** Implementar una Cloud Function con Admin SDK que escuche cambios en pedidos (p. ej. `estado == 'entregado'`) y ejecute `acreditarPuntos` con privilegios de administrador. Alternativamente, ajustar las reglas para permitir que el dueño del lugar acredite puntos (requiere estructura de datos adicional para vincular lugares y permisos).

- **historial_puntos:** `allow write: if isLoggedIn()`
  - Cualquier usuario autenticado puede escribir. Un atacante podría agregar entradas falsas al historial, pero **no** puede modificar el campo `barPoints` del documento de usuario (protegido por la regla del padre). El riesgo es limitado pero conviene restringir.

### Seguridad de barPoints

- El usuario **sí** puede escribir en su propio documento (`isOwner(userId)`). Si el cliente modifica la app o usa APIs directamente, podría intentar cambiar `barPoints`.
- Las reglas no distinguen campos; permiten cualquier escritura del dueño. Mitigación: usar Cloud Functions para operaciones sensibles o validar en reglas con `request.resource.data` (p. ej. solo permitir incrementos controlados).

---

## Manejo de Red y Fallos

### Rollback

- Las transacciones de Firestore son atómicas: o se confirman todas las operaciones o ninguna. No se requieren rollbacks manuales.
- Si la transacción falla (red, concurrencia), el cliente recibe error y puede reintentar. El estado queda consistente.

### Recuperación

- Si el pedido se crea pero falla el marcado del cupón (flujo anterior): el cupón podía quedar sin marcar. Con la transacción atómica, esto ya no ocurre.
- Si la red se corta **durante** la transacción: Firestore aborta y no persiste nada. El usuario debe reintentar.

---

## Resumen de Archivos Modificados

| Archivo | Cambios |
|---------|---------|
| `lib/services/barpoints_service.dart` | `canjearPuntos` y `acreditarPuntos` con `runTransaction`; eliminado `_crearCuponBarPoints` (lógica inlined) |
| `lib/services/coupons_service.dart` | `codigoYaUsado`: retorno `true` ante error (fail-closed) |
| `lib/ui/client/logic/checkout_logic.dart` | Transacción atómica pedido+cupón; redondeo de montos; validación de venue en transacción |
| `lib/ui/client/client_checkout_screen.dart` | Eliminado registro duplicado de cupón; redondeo en descuento |

---

## Implementación Post-Auditoría: Cloud Function onOrderDelivered

**Implementado (Feb 2025):** La acreditación de puntos ahora se realiza en el servidor mediante la Cloud Function `onOrderDelivered`:

- **Trigger:** `onUpdate` en `places/{placeId}/orders/{orderId}` cuando `estado` pasa a `entregado`
- **Lógica:** Verifica `puntosAcreditados === false`, usa Admin SDK en transacción atómica para:
  - Sumar barPoints al usuario (con redondeo `round(val*100)/100`)
  - Marcar `puntosAcreditados: true`
  - Crear entrada en `historial_puntos`
- **Reglas Firestore:** Los usuarios no pueden aumentar su `barPoints` (solo disminuir en canje). `historial_puntos` solo escribe desde Cloud Functions.
- **Frontend:** Se eliminó la llamada manual a `BarPointsService.acreditarPuntos` en `delivery_logic.dart`.

---

## Recomendaciones Adicionales

1. ~~**Cloud Function para acreditación de puntos:**~~ ✅ Implementado (`onOrderDelivered`).
2. **Reglas más restrictivas para historial_puntos:** Limitar la escritura al propio usuario (o a un rol de sistema) en lugar de `isLoggedIn()`.
3. **Idempotencia:** Para reintentos, usar un `idempotencyKey` por operación cuando sea posible.
4. **Monitoring:** Registrar eventos de fallo en transacciones (doble gasto, cupón ya usado) para detectar intentos de abuso.
