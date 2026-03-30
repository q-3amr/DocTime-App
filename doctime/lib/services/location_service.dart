import 'package:geolocator/geolocator.dart';

class LocationService {
  
  // دالة لجلب الموقع الحالي للمستخدم
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. فحص إذا كانت خدمة الـ GPS مفعلة في الجهاز
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('خدمات الموقع معطلة. يرجى تفعيل الـ GPS.');
    }

    // 2. فحص صلاحيات الوصول للموقع
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // نطلب الصلاحية من المستخدم إذا كانت مرفوضة
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('تم رفض صلاحيات الموقع.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('صلاحيات الموقع مرفوضة بشكل دائم، يرجى تفعيلها من الإعدادات.');
    } 

    // 3. جيب الإحداثيات (Latitude & Longitude) بدقة عالية
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
  }
}