// lib/main.dart
import 'dart:async'; // Para runZonedGuarded
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

import 'ui/auth/auth_gate.dart';
import 'ui/place/place_detail_screen.dart';
import 'ui/chat/chat_screen.dart';
import 'package:barapp/ui/events/events_screen.dart';
import 'providers/blocked_users_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Handler de fondo (Solo para Android/iOS)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Notificación en 2do plano: ${message.messageId}");
  }
}

void main() async {
  // 🔥 ZONA SEGURA: Captura errores globales
  runZonedGuarded(() async {
    
    // 🛠️ FIX 1: Usamos la clase concreta WidgetsFlutterBinding
    WidgetsFlutterBinding.ensureInitialized();

    // 1. INICIALIZAR FIREBASE (requiere dart_defines.json)
    final opts = DefaultFirebaseOptions.currentPlatform;
    if (opts.apiKey.isEmpty) {
      throw Exception(
        'Configura las claves: copia dart_defines.json.example a dart_defines.json, '
        'rellena las claves y ejecuta con: flutter run --dart-define-from-file=dart_defines.json',
      );
    }
    await Firebase.initializeApp(options: opts);

    // 🛡️ LÓGICA SOLO PARA MÓVILES (Android/iOS)
    if (!kIsWeb) {
      // A. Persistencia Offline (Solo móvil)
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e) {
        debugPrint("⚠️ No se pudo activar persistencia móvil: $e");
      }

      // B. Inicializar Notificaciones Locales (NO EJECUTAR EN WEB)
      try {
        await NotificationService.init();
      } catch (e) {
        debugPrint("Error iniciando NotificationService: $e");
      }

      // C. Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // D. Bloquear Orientación
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    } 
    // 🛠️ FIX 2: Quitamos la configuración explícita de persistencia en Web.
    // Dejamos que Firebase Web use su configuración por defecto para evitar el error.

    // 3. CONFIGURAR FORMATO DE FECHAS
    await initializeDateFormatting('es_ES', null);

    // 🚀 ARRANQUE
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => BlockedUsersProvider()),
        ],
        child: const BarAppUniversal(),
      ),
    );
  }, (error, stack) {
    // 🔥 AQUÍ CAEN LOS ERRORES CRÍTICOS
    debugPrint("🔴 ERROR CRÍTICO NO CONTROLADO: $error");
    debugPrint(stack.toString());
  });
}

class BarAppUniversal extends StatefulWidget {
  const BarAppUniversal({super.key});

  @override
  State<BarAppUniversal> createState() => _BarAppUniversalState();
}

class _BarAppUniversalState extends State<BarAppUniversal> {
  @override
  void initState() {
    super.initState();
    _safeInit();
  }

  Future<void> _safeInit() async {
    // 1. Notificaciones
    try {
      await _setupNotifications();
    } catch (e) {
      debugPrint("⚠️ Error setup notificaciones: $e");
    }

    // 2. Interacciones (Solo móvil)
    if (!kIsWeb) {
      try {
        _setupInteractions();
      } catch (e) {
        debugPrint("⚠️ Error setup interacciones: $e");
      }
    }

    // 3. Web Navigation (QR)
    if (kIsWeb) {
      try {
        _checkWebNavigation();
      } catch (e) {
        debugPrint("⚠️ Error web navigation: $e");
      }
    }

    // 4. Suscripción Global (Con protección Web)
    _subscribeToGlobalTopics();

    // 5. Auth Listener
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _saveUserToken(user);
      }
    });
  }

  void _subscribeToGlobalTopics() async {
    // 🔥 CORRECCIÓN CRÍTICA: En Web esto rompe la app.
    if (kIsWeb) return; 

    try {
      await FirebaseMessaging.instance.subscribeToTopic('events'); 
      debugPrint("🔔 Suscrito al topic GLOBAL: events");
    } catch (e) {
      debugPrint("⚠️ Error suscribiendo a topic events: $e");
    }
  }

  Future<void> _saveUserToken(User user) async {
    try {
      // getToken en web puede fallar si no hay VAPID key configurada, lo ignoramos.
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
              'fcmToken': token,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
              'platform': kIsWeb ? 'web' : defaultTargetPlatform.toString(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      // debugPrint("⚠️ Token FCM no disponible: $e");
    }
  }

  Future<void> _safeSubscribeToTopic(String topic) async {
    if (kIsWeb) return;

    try {
      final messaging = FirebaseMessaging.instance;
      for (int i = 0; i < 5; i++) {
        final apnsToken = await messaging.getAPNSToken();
        if (defaultTargetPlatform == TargetPlatform.android || apnsToken != null) {
          await messaging.subscribeToTopic(topic);
          debugPrint('📱 Subscribed to $topic');
          return;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      debugPrint('⚠️ Error subscribing to $topic: $e');
    }
  }

  Future<void> _setupNotifications() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await _safeSubscribeToTopic('events');

        if (!kIsWeb) {
          await FirebaseMessaging.instance
              .setForegroundNotificationPresentationOptions(
                alert: false, 
                badge: true,
                sound: true,
              );
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (!kIsWeb) {
            try {
              NotificationService.showNotification(message);
            } catch (e) {
              debugPrint("Error mostrando notificación local: $e");
            }
          } else {
            debugPrint("🔔 Notificación recibida en Web: ${message.notification?.title}");
          }
        });

        messaging.onTokenRefresh.listen((newToken) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) _saveUserToken(user);
          _safeSubscribeToTopic('events'); 
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error setup notificaciones: $e");
    }
  }

  Future<void> _setupInteractions() async {
    if (kIsWeb) return;

    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleMessage(initialMessage);
        });
      }
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleMessage(message);
      });
    } catch (e) {
      debugPrint("⚠️ Error setup interacciones: $e");
    }
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      final String? type = message.data['type'];
      final String? id = message.data['id'];
      final String? extraName = message.data['extraName'];

      if (type == 'event') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const EventsScreen()),
        );
        return; 
      }

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
    }
  }

  Future<void> _checkWebNavigation() async {
    if (kIsWeb) {
      try {
        final String? placeId = Uri.base.queryParameters['id'];

        if (placeId != null && placeId.isNotEmpty) {
          if (FirebaseAuth.instance.currentUser == null) {
            try {
              await FirebaseAuth.instance.signInAnonymously();
              debugPrint("Login anónimo exitoso para QR");
            } catch (e) {
              debugPrint("Error en login anónimo: $e");
            }
          }

          Future.delayed(const Duration(milliseconds: 800), () {
            if (navigatorKey.currentState != null) {
              navigatorKey.currentState!.push(
                MaterialPageRoute(
                  builder: (_) => PlaceDetailScreen(placeId: placeId),
                ),
              );
            }
          });
        }
      } catch (e) {
        debugPrint("Error web navigation: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'BarApp',
      theme: buildBaseTheme(),
      scrollBehavior: MyCustomScrollBehavior(),
      home: const AuthGate(),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}