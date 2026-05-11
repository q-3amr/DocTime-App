import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart'; // السطر الجديد
import 'auth_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// دالة للتعامل مع الإشعارات في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 1. إعداد الرسائل في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. طلب الصلاحية باستخدام permission_handler (حل مشكلة الكراش)
  await _handlePermissions();

  // 3. طلب الصلاحية من Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
} // تأكدي إن القوس مسكر هون قبل ما تبدأي الدالة اللي تحت

// الدالة السحرية (Handling Deny)
Future<void> _handlePermissions() async {
  try {
    // طلب صلاحية الإشعارات
    PermissionStatus status = await Permission.notification.request();

    if (status.isGranted) {
      debugPrint("تم السماح بالإشعارات");
    } else if (status.isDenied) {
      debugPrint("تم رفض الإشعارات - التطبيق سيستمر بالعمل");
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
