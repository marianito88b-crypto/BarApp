// services/notification_service.dart

import 'dart:convert'; // 1. NUEVO: Para convertir datos a texto (JSON)
import 'package:universal_io/io.dart'; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart'; // Necesario para MaterialPageRoute
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// 2. NUEVO: Importamos main para usar la navigatorKey
import 'package:barapp/main.dart'; 
// 3. NUEVO: Importamos las pantallas a las que queremos ir
import 'package:barapp/ui/events/events_screen.dart';
import 'package:barapp/ui/place/place_detail_screen.dart';
import 'package:barapp/ui/chat/chat_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    // 4. CAMBIO CRÍTICO: Agregamos onDidReceiveNotificationResponse
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationTap(response);
      },
    );

    // NOTA: No necesitamos escuchar onMessage aquí si ya lo llamamos desde main.dart
    // Pero si lo dejas no pasa nada, solo asegúrate de no duplicar notificaciones.
  }

  // 5. NUEVA FUNCIÓN: Qué hacer al tocar la notificación LOCAL (App abierta)
  static void _onNotificationTap(NotificationResponse response) {
    final String? payload = response.payload;
    
    if (payload != null && payload.isNotEmpty) {
      try {
        // 1. Decodificamos el JSON
        final Map<String, dynamic> data = jsonDecode(payload);
        
        // 2. EXTRAEMOS TODAS LAS VARIABLES (Aquí estaba el error antes)
        final String? type = data['type'];
        final String? id = data['id'];              // <--- Faltaba definir esto
        final String? extraName = data['extraName']; // <--- Y esto

        debugPrint("🔔 Tap en notificación local -> Tipo: $type | ID: $id");

        // 3. CASO EVENTOS (Prioridad: No necesita ID)
        if (type == 'event') {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const EventsScreen()),
          );
          return; // Cortamos aquí
        }

        // 4. CASOS QUE REQUIEREN ID (Lugares y Chats)
        if (id != null) {
          if (type == 'bar_detail') {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: id)),
            );
          } else if (type == 'chat') {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  otherUserId: id, 
                  otherDisplayName: extraName ?? 'Chat',
                ),
              ),
            );
          }
        }

      } catch (e) {
        debugPrint("Error al procesar click de notificación local: $e");
      }
    }
  }

  static Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    if (kIsWeb) return null; 

    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/$fileName';
      final http.Response response = await http.get(Uri.parse(url));
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      debugPrint("Error descargando imagen: $e");
      return null;
    }
  }

  static Future<void> showNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final data = message.data;
    final notification = message.notification;

    // Si no hay notificación visible, no mostramos nada local
    if (notification == null) return;

    BigPictureStyleInformation? bigPictureStyleInformation;
    
    String? imageUrl = message.notification?.android?.imageUrl ?? data['image'];

    if (imageUrl != null && imageUrl.isNotEmpty && !kIsWeb) {
      final String? bigPicturePath = await _downloadAndSaveFile(imageUrl, 'bigPicture');
      
      if (bigPicturePath != null) {
        bigPictureStyleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(bigPicturePath),
          largeIcon: FilePathAndroidBitmap(bigPicturePath),
          contentTitle: notification.title,
          htmlFormatContentTitle: true,
          summaryText: notification.body,
          htmlFormatSummaryText: true,
        );
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'event_channel', 
      'Eventos y Promos', 
      channelDescription: 'Notificaciones de nuevos eventos',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigPictureStyleInformation, 
    );

    final details = NotificationDetails(android: androidDetails);

    // 6. CAMBIO CRÍTICO: Pasamos 'payload' para que funcione el click
    await _notifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(data), // Guardamos la data como texto oculto
    );
  }
}