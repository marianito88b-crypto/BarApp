# Análisis completo del sistema BarPoints

## Resumen ejecutivo

BarPoints es el programa de fidelización de BarApp. Existen **dos formas** de ganar puntos en el código actual.

---

## Forma 1: Puntos por compra

### ¿Cómo se ganan?

Por cada **$1.000 (pesos)** del total del pedido, ganás **1 punto**.  
Fórmula: `floor(total / 1000)` — se usa la parte entera (ej: $2.499 → 2 puntos).

### Condiciones que debés cumplir

1. **Estar logueado** al momento de hacer el pedido (el pedido debe tener `userId`).
2. **Pedido desde la app** (delivery o retiro) — no aplica a pedidos de mesas físicas o por otro canal.
3. **Total del pedido ≥ $1.000** — si el total es menor, no se acreditan puntos.
4. **El bar marca el pedido como "entregado"** — los puntos se acreditan solo cuando el dueño/repartidor finaliza la venta desde el panel.
5. **Los puntos no deben haberse acreditado antes** — se evita duplicar acreditaciones.

### Detalles técnicos

| Archivo | Rol |
|---------|-----|
| `checkout_logic.dart` | Calcula `puntosEstimados` al crear el pedido y lo guarda en el documento. Usa el `total` final (después de descuentos). |
| `delivery_logic.dart` | Al marcar el pedido como entregado (`finalizeAndMoveToSales`), llama a `BarPointsService.acreditarPuntos()`. |
| `barpoints_service.dart` | `acreditarPuntos()` actualiza `barPoints` del usuario y crea el movimiento en `historial_puntos`. |

### Concepto en el historial

"Compra en {nombre del bar}" (ej: "Compra en Bar de Moe").

---

## Forma 2: Bonus por calificaciones recibidas

### ¿Cómo se ganan?

Cuando un **bar te califica como cliente**, cada vez que tu contador global de calificaciones llega a **3, 6, 9, 12...** (múltiplos de 3), recibís **+10 BarPoints** de bonus.

### Condiciones que debés cumplir

1. Un bar debe **calificarte** — desde el panel del dueño, cuando finaliza un pedido y usa el diálogo "Calificar Cliente".
2. **No podés ser el dueño** del bar que te califica — se bloquea que te califiques a vos mismo.
3. Tu perfil debe existir en `users` o `usuarios` — para poder actualizar los puntos.
4. El bonus se da **globalmente** — no por bar: la 3.ª calificación que recibís de cualquier bar, la 6.ª, etc.

### Detalles técnicos

| Archivo | Rol |
|---------|-----|
| `rating_service.dart` | En `calificarCliente()` incrementa `total_ratings`. Si `total_ratings % 3 == 0`, suma 10 a `barPoints` y llama a `BarPointsService.registrarMovimiento()`. |
| `client_rating_dialog.dart` | UI donde el dueño califica al cliente. |
| `delivery_logic.dart` | Muestra el diálogo de calificación al finalizar un pedido. |

### Concepto en el historial

"Bonus 3ra calificación" (o equivalente: la 6.ª, 9.ª, etc.).

---

## Coherencia con la pantalla `bar_points_detail_screen`

### Lo que la pantalla decía antes

- **Sumá**: "Por cada $1.000 de compra, ganás 1 punto." — ✅ Correcto.
- **Acumulá**: "Tus puntos se guardan en tu perfil." — ✅ Correcto.
- **Canjeá**: "Usalos para obtener descuentos en locales adheridos." — ✅ Correcto (descripción de uso).

### Lo que faltaba

- No se mencionaba el **bonus por calificaciones** (+10 puntos cada 3 calificaciones de bares).

### Corrección aplicada

Se agregó un cuarto paso en "Cómo funciona" para explicar el bonus por calificaciones, de forma coherente con el código.

---

## Resumen de flujos

```
[Cliente hace pedido en app] 
    → checkout_logic guarda puntosEstimados = floor(total/1000)
    → Pedido queda en estado pendiente/confirmado/... 

[Bar marca pedido como entregado]
    → delivery_logic.finalizeAndMoveToSales()
    → BarPointsService.acreditarPuntos()
    → +puntos en barPoints
    → Movimiento "Compra en {bar}" en historial_puntos
    → Se muestra diálogo para calificar al cliente

[Bar califica al cliente]
    → rating_service.calificarCliente()
    → total_ratings++
    → Si total_ratings % 3 == 0: +10 barPoints
    → Movimiento "Bonus 3ra calificación" en historial_puntos
```

---

## Otros archivos que usan BarPoints

- `top_clients_ranking.dart`: Ordena clientes por `barPoints` para el ranking.
- `barpoints_card.dart`: Muestra el saldo en el perfil y navega a la pantalla de detalle.
