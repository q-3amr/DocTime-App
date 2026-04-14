import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// المسار الدقيق بناءً على ترتيب مجلداتك
import '../common/base_map_screen.dart';

class PatientMapScreen extends BaseMapScreen {
  const PatientMapScreen({super.key});

  @override
  State<PatientMapScreen> createState() => _PatientMapScreenState();
}

class _PatientMapScreenState extends BaseMapState<PatientMapScreen> {
  // بيانات وهمية مؤقتة للعيادات (لبين ما نربطها بـ Firebase)
  final Map<String, LatLng> mockClinics = {
    'عيادة د. أحمد (باطنية)': const LatLng(31.9600, 35.9100),
    'عيادة د. سارة (أسنان)': const LatLng(31.9500, 35.9200),
  };

  String? selectedClinicName;
  LatLng? selectedClinicLocation;

  // 1. تحديد الدبابيس (عرض كل العيادات)
  @override
  Set<Marker> get markers {
    return mockClinics.entries.map((entry) {
      return Marker(
        markerId: MarkerId(entry.key),
        position: entry.value,
        // تغيير لون الدبوس لتمييزه
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () {
          // لما المريض يكبس على عيادة
          setState(() {
            selectedClinicName = entry.key;
            selectedClinicLocation = entry.value;
          });
        },
      );
    }).toSet();
  }

  // 2. عند الضغط على مكان فارغ بالخريطة
  @override
  void onMapTapped(LatLng position) {
    // إخفاء الشاشة السفلية إذا كبس برا الدبوس
    setState(() {
      selectedClinicName = null;
      selectedClinicLocation = null;
    });
  }

  // 3. الشاشة السفلية (اسم العيادة وزر الاتجاهات)
  @override
  Widget? buildBottomPanel() {
    if (selectedClinicName == null)
      return null; // ما بتطلع إلا إذا كبس على عيادة

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2))
      ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(selectedClinicName!,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              // هذا الزر حالياً بطبع رسالة، لاحقاً رح نربطه بـ Google Maps الفعلي
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('جاري فتح الاتجاهات إلى $selectedClinicName...')));
            },
            icon: const Icon(Icons.directions, color: Colors.white),
            label: const Text('الاتجاهات',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
