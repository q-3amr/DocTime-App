import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 1. إعداد القناة (Channel) لإظهار الإشعار كـ "بانر" (Heads-up)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// دالة للتعامل مع الإشعارات في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // تهيئة الإشعارات المحلية (لأندرويد)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // طلب الصلاحيات
  await _handlePermissions();

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // الحصول على الـ Device Token لغرض التجربة
  String? token = await messaging.getToken();
  debugPrint("Device Token: $token");

  // استقبال الإشعار وهو التطبيق مفتوح (Foreground)
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
            importance: Importance.high, // يضمن ظهور "البانر"
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

Future<void> _handlePermissions() async {
  try {
    PermissionStatus status = await Permission.notification.request();
    if (status.isGranted) {
      debugPrint("تم السماح بالإشعارات");
    }
  } catch (e) {
    debugPrint("Error in permissions: $e");
  }
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
