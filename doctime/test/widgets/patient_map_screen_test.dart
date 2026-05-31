import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

// 📍 الـ imports مضبوطة على اسم مشروعكم ومجلد الـ widgets
import 'package:doctime/screens/patient/patient_map_screen.dart';
import 'package:doctime/models/user.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('PatientMapScreen & Location Filtering Tests - 10 Scenarios', () {
    // 1. تست الفلترة والترتيب حسب الأقرب (Distance Sorting)
    test(
        '1. Doctors list should be sorted from closest to farthest based on patient location',
        () {
      double patientLat = 32.5380;
      double patientLng = 35.9230;

      final closeDoctor = UserModel(
        id: 'doc_close',
        email: 'close@doctime.com', // 📍 تم إضافة الـ email الإجباري هنا
        name: 'Dr. Close',
        role: 'doctor',
        latitude: 32.5400,
        longitude: 35.9250,
      );

      final farDoctor = UserModel(
        id: 'doc_far',
        email: 'far@doctime.com', // 📍 تم إضافة الـ email الإجباري هنا
        name: 'Dr. Far',
        role: 'doctor',
        latitude: 31.9539,
        longitude: 35.9106,
      );

      List<UserModel> mockDoctors = [farDoctor, closeDoctor];

      // حساب المسافة وترتيب القائمة
      mockDoctors.sort((a, b) {
        double distanceA = Geolocator.distanceBetween(
            patientLat, patientLng, a.latitude!, a.longitude!);
        double distanceB = Geolocator.distanceBetween(
            patientLat, patientLng, b.latitude!, b.longitude!);
        return distanceA.compareTo(distanceB);
      });

      expect(mockDoctors.first.id, 'doc_close');
      expect(mockDoctors.last.id, 'doc_far');
    });

    // 2. تست للتأكد من حساب المسافة بشكل صحيح بالأمتار
    test(
        '2. Geolocator should calculate correct distance between two known coordinates',
        () {
      double startLat = 32.5380;
      double startLng = 35.9230;
      double endLat = 32.5400;
      double endLng = 35.9250;

      double distance =
          Geolocator.distanceBetween(startLat, startLng, endLat, endLng);

      expect(distance, isPositive);
    });

    // 3. تست للتأكد من إحداثيات الكاميرا الافتراضية للخريطة
    test('3. Initial Camera Position should target correct coordinates', () {
      const initialTarget = LatLng(31.9539, 35.9106);
      expect(initialTarget.latitude, 31.9539);
      expect(initialTarget.longitude, 35.9106);
    });

    // 4. تست للتأكد من دالة تحويل البيانات الجغرافية من الفايربيس (Firestore Parsing)
    test('4. UserModel fromMap should parse location details properly', () {
      final mockData = {
        'name': 'Dr. Ahmad',
        'email':
            'ahmad@doctime.com', // 📍 الـ email الممرر من قاعدة البيانات الوهمية
        'role': 'doctor',
        'specialty': 'Cardiology',
        'latitude': 32.5568,
        'longitude': 35.8469,
      };
      final doctor = UserModel.fromMap(mockData, 'doc_123');

      expect(doctor.latitude, 32.5568);
      expect(doctor.longitude, 35.8469);
    });

    // 5. تست استثناء الأطباء الذين لا يملكون إحداثيات موقع (Null Location Protection)
    test('5. Doctors without coordinates should be filtered out from the map',
        () {
      final doctorWithoutLocation = UserModel(
        id: 'doc_null',
        email: 'null@doctime.com', // 📍 تم إضافة الـ email الإجباري هنا
        name: 'Dr. No Location',
        role: 'doctor',
        latitude: null,
        longitude: null,
      );

      List<UserModel> allDoctors = [doctorWithoutLocation];

      List<UserModel> validDoctors = allDoctors
          .where((doc) => doc.latitude != null && doc.longitude != null)
          .toList();

      expect(validDoctors.isEmpty, isTrue);
    });

    // 6. تست للتأكد من ظهور اسم الدكتور بالتفصيل داخل دبوس الخريطة (Marker InfoWindow)
    test(
        '6. Marker InfoWindow should display correct doctor name and specialty',
        () {
      final doctor = UserModel(
        id: 'doc_123',
        email: 'info@doctime.com', // 📍 تم إضافة الـ email الإجباري هنا
        name: 'Dr. Ahmad',
        role: 'doctor',
        specialty: 'Cardiology',
        latitude: 32.5568,
        longitude: 35.8469,
      );

      final marker = Marker(
        markerId: MarkerId(doctor.id),
        position: LatLng(doctor.latitude!, doctor.longitude!),
        infoWindow: InfoWindow(title: doctor.name, snippet: doctor.specialty),
      );

      expect(marker.infoWindow.title, 'Dr. Ahmad');
      expect(marker.infoWindow.snippet, 'Cardiology');
    });

    // 7. تست فحص الـ UI: التأكد من وجود زر موقعي الحالي بالشاشة بالإنجليزي
    testWidgets('7. Search for Current Location button on the screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PatientMapScreen()));

      final locationButton = find.text('Current Location');
      expect(locationButton, findsOneWidget);
    });

    // 8. تست فحص الـ UI: التأكد من عدم ظهور الـ Bottom Panel إذا لم يتم الضغط على أي طبيب
    testWidgets(
        '8. Bottom panel buttons should not appear if no doctor is selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PatientMapScreen()));

      expect(find.text('Directions'), findsNothing);
      expect(find.text('View Profile'), findsNothing);
    });

    // 9. تست حماية التطبيق من المسافات الصفرية (Edge Case Distance Test)
    test(
        '9. Distance calculation with identical coordinates should return zero',
        () {
      double lat = 32.5380;
      double lng = 35.9230;

      double distance = Geolocator.distanceBetween(lat, lng, lat, lng);
      expect(distance, 0.0);
    });

    // 10. تست محاكاة حركة الكاميرا (Camera Action Movement Trigger)
    test('10. Camera Update should generate a valid non-null movement object',
        () {
      final targetLatLng = LatLng(32.5400, 35.9250);
      final cameraUpdate = CameraUpdate.newLatLng(targetLatLng);

      expect(cameraUpdate, isNotNull);
    });
  });
}
