import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 👈 تأكد من إضافة intl في pubspec.yaml أو استخدم التنسيق اليدوي

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _buttonIndex = 0; // 0: Upcoming, 1: History (Completed/Expired/Cancelled)
  final User? user = FirebaseAuth.instance.currentUser;
  bool isDoctor = false;
  bool isLoading = true;
  final Color primaryBlue = const Color(0xFF407CE2);

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  void _checkRole() async {
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('doctors').doc(user!.uid).get();
      if (mounted) setState(() { isDoctor = doc.exists; isLoading = false; });
    }
  }

  // 🛠️ حل مشكلة Timestamp
  DateTime _parseDate(dynamic dateData) {
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is String) return DateTime.tryParse(dateData) ?? DateTime.now();
    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    // تنسيق يدوي بسيط وجميل (YYYY-MM-DD)
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _cancelAppointment(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Appointment?"),
        content: const Text("Are you sure you want to cancel this appointment?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('appointments').doc(docId).update({'status': 'cancelled'});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment Canceled")));
    }
  }

  // 🗑️ حذف من السجل (للمريض فقط)
  void _deleteAppointment(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete from History?"),
        content: const Text("This will remove the record permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('appointments').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Schedule", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [_buildTab("Upcoming", 0), _buildTab("History", 1)]),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where(isDoctor ? 'doctor_id' : 'patient_id', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  var docs = snapshot.data!.docs;
                  var now = DateTime.now();

                  // 🧠 الفلتر الذكي
                  var filteredDocs = docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String status = data['status'];
                    DateTime date = _parseDate(data['date']);
                    bool isPast = date.isBefore(now);

                    if (_buttonIndex == 0) {
                      // Upcoming: لازم تكون accepted + مستقبلية
                      return status == 'accepted' && !isPast;
                    } else {
                      // History: مكتملة OR ملغية OR (مقبولة بس راحت عليها - Expired)
                      return status == 'completed' || status == 'cancelled' || status == 'rejected' || (status == 'accepted' && isPast);
                    }
                  }).toList();

                  // ترتيب حسب التاريخ
                  filteredDocs.sort((a, b) {
                    DateTime dateA = _parseDate((a.data() as Map)['date']);
                    DateTime dateB = _parseDate((b.data() as Map)['date']);
                    return _buttonIndex == 0 ? dateA.compareTo(dateB) : dateB.compareTo(dateA); // Upcoming: الأقرب، History: الأحدث
                  });

                  if (filteredDocs.isEmpty) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.event_busy, size: 70, color: Colors.grey.shade300),
                      Text("No appointments", style: TextStyle(color: Colors.grey.shade400)),
                    ]));
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      return _buildCard(filteredDocs[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    bool active = _buttonIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _buttonIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: active ? primaryBlue : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    String name = isDoctor ? (data['patient_name'] ?? "Patient") : (data['doctor_name'] ?? "Doctor");
    DateTime dateObj = _parseDate(data['date']);
    String dateStr = _formatDate(dateObj); // استخدام الدالة للإصلاح
    String timeStr = "${dateObj.hour > 12 ? dateObj.hour - 12 : (dateObj.hour == 0 ? 12 : dateObj.hour)}:${dateObj.minute.toString().padLeft(2, '0')} ${dateObj.hour >= 12 ? 'PM' : 'AM'}";
    
    bool isPast = dateObj.isBefore(DateTime.now());
    String status = data['status'];
    String displayStatus = status;
    Color statusColor = Colors.green;

    if (status == 'accepted' && !isPast) {
      displayStatus = "Upcoming";
      statusColor = Colors.blue;
    } else if (status == 'accepted' && isPast) {
      displayStatus = "Expired";
      statusColor = Colors.orange;
    } else if (status == 'cancelled') {
      displayStatus = "Cancelled";
      statusColor = Colors.red;
    } else {
      displayStatus = "Completed";
      statusColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: statusColor.withOpacity(0.1), child: Icon(Icons.person, color: statusColor)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(displayStatus, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
              // زر الإلغاء (للمواعيد القادمة)
              if (!isDoctor && displayStatus == "Upcoming")
                IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent), onPressed: () => _cancelAppointment(doc.id)),
              // زر الحذف (للسجل)
              if (!isDoctor && _buttonIndex == 1)
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => _deleteAppointment(doc.id)),
            ],
          ),
          const Divider(height: 25),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)), // التاريخ الصحيح
              const Spacer(),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)), // الوقت الصحيح
            ],
          )
        ],
      ),
    );
  }
}