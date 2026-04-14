import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// المسار الدقيق بناءً على ترتيب مجلداتك
import '../common/base_map_screen.dart';

class DoctorMapScreen extends BaseMapScreen {
  const DoctorMapScreen({super.key});

  @override
  State<DoctorMapScreen> createState() => _DoctorMapScreenState();
}

class _DoctorMapScreenState extends BaseMapState<DoctorMapScreen> {
  LatLng? pickedClinicLocation;

  // 1. تحديد الدبابيس (دبوس واحد فقط للعيادة)
  @override
  Set<Marker> get markers {
    if (pickedClinicLocation == null) return {};
    return {
      Marker(
        markerId: const MarkerId('picked_clinic'),
        position: pickedClinicLocation!,
      )
    };
  }

  // 2. عند الضغط على الخريطة (الدكتور بضيف دبوس)
  @override
  void onMapTapped(LatLng position) {
    setState(() {
      pickedClinicLocation = position;
    });
  }

  // 3. الشاشة السفلية (زر تأكيد الموقع)
  @override
  Widget? buildBottomPanel() {
    if (pickedClinicLocation == null)
      return null; // ما بيطلع الزر إلا إذا حدد موقع

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          // إرجاع الإحداثيات لشاشة التسجيل
          Navigator.of(context).pop(pickedClinicLocation);
        },
        child: const Text('تأكيد موقع العيادة',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}
