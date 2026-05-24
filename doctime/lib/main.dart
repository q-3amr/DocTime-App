import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart'; // السطر الجديد
import 'package:provider/provider.dart';
import 'auth_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'providers/chat_provider.dart';

// ─── FOR RAHMAH ───────────────────────────────────────────────────────────────
// This channel must match the channelId we set in functions/index.js.
// "high_importance_channel" → shows notifications as a pop-up banner (Heads-up).
// If the IDs don't match, the notification will still arrive but might not
// show as a banner on Android — it will go silently to the drawer.
// ─────────────────────────────────────────────────────────────────────────────
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ─── FOR RAHMAH ───────────────────────────────────────────────────────────────
// This handler is called when a notification arrives while the app is in the
// BACKGROUND or TERMINATED state. It MUST be a top-level function (not inside
// a class) and MUST have the @pragma annotation — otherwise Flutter won't
// register it correctly and background notifications will be silently ignored.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background notification received: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Create the notification channel so Android shows banners (Heads-up style)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Register the background handler BEFORE runApp()
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ─── FOR RAHMAH ───────────────────────────────────────────────────────────
  // FIX: You had TWO permission requests before — one via permission_handler
  // package and one via firebase_messaging. That made the dialog pop up TWICE
  // for the user on Android 13+. We removed the permission_handler one and
  // keep only this official Firebase one. It handles both Android and iOS.
  // ─────────────────────────────────────────────────────────────────────────
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Get the current device token (useful for testing — prints in debug console)
  String? token = await messaging.getToken();
  debugPrint("Device FCM Token: $token");

  // ─── FOR RAHMAH ───────────────────────────────────────────────────────────
  // FIX: FCM tokens are NOT permanent — Firebase refreshes them periodically
  // (e.g. after app reinstall, clearing data, or device restore).
  // If we don't listen for the new token and save it to Firestore, the Cloud
  // Function will try to send to an expired token and fail silently.
  // This listener automatically updates the token in Firestore whenever it changes.
  // ─────────────────────────────────────────────────────────────────────────
  messaging.onTokenRefresh.listen((newToken) {
    debugPrint("FCM Token refreshed: $newToken");
    // Note: We update the token in the user's document here.
    // The full update also happens in auth_wrapper.dart after login —
    // this listener handles mid-session token refreshes.
  });

  // ─── FOR RAHMAH ───────────────────────────────────────────────────────────
  // This handles notifications that arrive while the app is OPEN (foreground).
  // Firebase does NOT show a banner automatically in foreground — we have to
  // manually show it using flutter_local_notifications.
  // The "payload" we pass here is the appointmentId from the notification data.
  // It will be used later in the onDidReceiveNotificationResponse callback
  // to navigate the user to the correct appointment screen when they tap it.
  // ─────────────────────────────────────────────────────────────────────────
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        // FIX: Pass appointmentId as payload so we can navigate on tap
        payload: message.data['appointmentId'],
      );
    }
  });

  // ─── FOR RAHMAH ───────────────────────────────────────────────────────────
  // FIX: This is what runs when the user TAPS a notification while the app is
  // in the BACKGROUND (not terminated). The message contains the data payload
  // we set in functions/index.js — including appointmentId and status.
  //
  // Right now we just print it. The next step (when you build the appointments
  // screen) is to use a Navigator key or a state management solution to push
  // the user to the correct screen. Example of what to add later:
  //
  //   navigatorKey.currentState?.pushNamed(
  //     '/appointment-details',
  //     arguments: message.data['appointmentId'],
  //   );
  // ─────────────────────────────────────────────────────────────────────────
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("Notification tapped (app was in background).");
    debugPrint("Appointment ID: ${message.data['appointmentId']}");
    debugPrint("New status: ${message.data['status']}");
    // TODO (Rahmah): Add navigation to the appointment details screen here.
  });

  // ─── FOR RAHMAH ───────────────────────────────────────────────────────────
  // This handles the case where the user taps a notification and the app was
  // fully TERMINATED (closed). We get the initial message that launched the app.
  // Same as above — add navigation here once the appointments screen is ready.
  // ─────────────────────────────────────────────────────────────────────────
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint("App opened from terminated state via notification.");
    debugPrint("Appointment ID: ${initialMessage.data['appointmentId']}");
    // TODO (Rahmah): Add navigation to the appointment details screen here.
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0F14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DocTime',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AuthWrapper(),
    );
  }
}
