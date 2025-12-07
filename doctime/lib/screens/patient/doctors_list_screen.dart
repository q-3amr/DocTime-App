import 'package:flutter/material.dart';
import 'package:doctime/models/doctor.dart';
import 'package:doctime/services/database_service.dart';

class DoctorsListScreen extends StatelessWidget {
  const DoctorsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Available Doctors')),
      body: StreamBuilder<List<DoctorModel>>(
        stream: db.streamDoctors(),
        builder: (context, snapshot) {
          // لسه بقرأ البيانات
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // صار خطأ
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final doctors = snapshot.data ?? [];

          // مافي دكاترة
          if (doctors.isEmpty) {
            return const Center(child: Text('No doctors found.'));
          }

          // في بيانات ✅
          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: doctor.imageUrl.isNotEmpty
                        ? NetworkImage(doctor.imageUrl)
                        : null,
                    child: doctor.imageUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    doctor.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${doctor.specialty} • ${doctor.location}\nRating: ${doctor.rating.toStringAsFixed(1)}',
                  ),
                  isThreeLine: true,
                  trailing: doctor.isVerified
                      ? const Icon(Icons.verified, color: Colors.green)
                      : null,
                  onTap: () {
                    // لاحقاً بنفتح صفحة تفاصيل الدكتور
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
