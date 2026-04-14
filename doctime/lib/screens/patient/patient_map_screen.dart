import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // مكتبة فتح التطبيقات الخارجية (Google Maps)
// تأكد من صحة مسار الاستدعاء حسب ترتيب مجلداتك
import '../common/base_map_screen.dart';
import '../../models/user.dart'; // استدعاء كلاس الـ User اللي عدلناه

class PatientMapScreen extends BaseMapScreen {
  const PatientMapScreen({super.key});

  @override
  State<PatientMapScreen> createState() => _PatientMapScreenState();
}

class _PatientMapScreenState extends BaseMapState<PatientMapScreen> {
  // 📍 متغيرات عشان نخزن الدكاترة اللي قرأناهم من الفايربيس
  List<UserModel> doctors = [];

  // 📍 متغيرات عشان نعرف أي دكتور المريض كبس عليه
  UserModel? selectedDoctor;

  @override
  void initState() {
    super.initState();
    _fetchDoctors(); // أول ما تفتح الشاشة، بنجيب الدكاترة من الفايربيس
  }

  // دالة لجلب الدكاترة اللي عندهم إحداثيات موقع فقط
  Future<void> _fetchDoctors() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      setState(() {
        doctors = snapshot.docs
            .map((doc) {
              return UserModel.fromMap(doc.data(), doc.id);
            })
            .where(
                (doctor) => doctor.latitude != null && doctor.longitude != null)
            .toList();
        // استخدمنا where عشان نستثني الدكاترة القدام اللي ما عندهم موقع
      });
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
    }
  }

  // ==========================================
  // 1. تحديد الدبابيس (عرض كل العيادات على الخريطة)
  // ==========================================
  @override
  Set<Marker> get markers {
    return doctors.map((doctor) {
      return Marker(
        markerId: MarkerId(doctor.id),
        position: LatLng(doctor.latitude!, doctor.longitude!),
        // بنغير لون الدبوس للأزرق عشان يكون مميز للمريض
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: doctor.name, snippet: doctor.specialty),
        onTap: () {
          // لما المريض يكبس على الدبوس، بنخزن الدكتور في المتغير عشان نعرض شاشته السفلية
          setState(() {
            selectedDoctor = doctor;
          });

          // حركة إضافية: بنخلي الكاميرا تقرب على العيادة اللي كبس عليها شوي
          mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(doctor.latitude!, doctor.longitude!)),
          );
        },
      );
    }).toSet();
  }

  // ==========================================
  // 2. عند الضغط على مكان فارغ بالخريطة
  // ==========================================
  @override
  void onMapTapped(LatLng position) {
    // إخفاء الشاشة السفلية إذا المريض كبس بمكان فاضي برا الدبوس
    setState(() {
      selectedDoctor = null;
    });
  }

  // ==========================================
  // 3. الشاشة السفلية (اسم العيادة وزر الاتجاهات)
  // ==========================================
  @override
  Widget? buildBottomPanel() {
    if (selectedDoctor == null) return null; // ما بتطلع إلا إذا كبس على عيادة

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -5),
            )
          ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.local_hospital, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedDoctor!.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      selectedDoctor!.specialty ?? 'General',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () => _openGoogleMapsDirections(
                selectedDoctor!.latitude!, selectedDoctor!.longitude!),
            icon: const Icon(Icons.directions_car, color: Colors.white),
            label: const Text('أرني الاتجاهات',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // دالة فتح تطبيق خرائط جوجل الحقيقي
  // ==========================================
  Future<void> _openGoogleMapsDirections(double lat, double lng) async {
    // هذا الرابط (URL) خاص بجوجل ماب، بقوله: "افتحلي اتجاهات قيادة السيارة (driving) لهاد الـ lat والـ lng"
    final Uri googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');

    // إذا التلفون فيه تطبيق خرائط جوجل (اندرويد) رح يفتحه، وإذا ما فيه رح يفتح المتصفح
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else {
        // بديل للآيفون أو إذا جوجل ماب مش نازل
        final Uri browserUrl = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
        if (await canLaunchUrl(browserUrl)) {
          await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('لا يمكن فتح الخرائط على هذا الجهاز')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء محاولة فتح الخرائط')),
        );
      }
    }
  }
}
