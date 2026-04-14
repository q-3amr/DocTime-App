import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

abstract class BaseMapScreen extends StatefulWidget {
  const BaseMapScreen({super.key});
}

abstract class BaseMapState<T extends BaseMapScreen> extends State<T> {
  GoogleMapController? mapController;
  Position? currentPosition;
  bool isLoading = false;

  final CameraPosition initialPosition = const CameraPosition(
    target: LatLng(31.9539, 35.9106),
    zoom: 13,
  );

  Set<Marker> get markers;
  Widget? buildBottomPanel();
  void onMapTapped(LatLng position);

  // ==========================================
  // الشاشة المنبثقة (Dialog) زي اللي بالصورة
  // ==========================================
  Future<void> _showLocationServiceDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // عشان ما يقدر يسكرها إلا إذا كبس كبسة
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('تفعيل الموقع',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
              'يرجى تفعيل خدمات الموقع (GPS) للسماح للتطبيق بتحديد موقعك بدقة.'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(); // بيسكر الشاشة
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('الإعدادات',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                Geolocator
                    .openLocationSettings(); // سحر! بفتح إعدادات التلفون فوراً
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // اللوجيك المعقد للصلاحيات
  // ==========================================
  Future<void> requestLocationAndGetPosition() async {
    setState(() => isLoading = true);

    try {
      // 1. فحص الـ GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => isLoading = false);
        await _showLocationServiceDialog(); // هون بنستدعي الشاشة تبعتك
        return;
      }

      // 2. فحص الصلاحيات (هاي بتطلع شاشة النظام الافتراضية للسماح/الرفض)
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage('تم رفض الصلاحية. لا يمكن تحديد الموقع.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
            'الصلاحيات مرفوضة نهائياً. يرجى تفعيلها من إعدادات التطبيق.');
        return;
      }

      // 3. الأمور تمام
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(currentPosition!.latitude, currentPosition!.longitude),
          15,
        ),
      );
    } catch (e) {
      _showMessage('حدث خطأ أثناء جلب الموقع');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخريطة', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialPosition,
            onMapCreated: (controller) => mapController = controller,
            markers: markers,
            onTap: onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (buildBottomPanel() != null)
            Positioned(
                bottom: 0, left: 0, right: 0, child: buildBottomPanel()!),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : requestLocationAndGetPosition,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.my_location),
      ),
    );
  }
}
