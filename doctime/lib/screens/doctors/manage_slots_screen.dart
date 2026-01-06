import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageSlotsScreen extends StatefulWidget {
  const ManageSlotsScreen({super.key});

  @override
  State<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends State<ManageSlotsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color primaryBlue = const Color(0xFF407CE2);
  DateTime _selectedDate = DateTime.now();
  List<String> _mySlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSlotsForDate(_selectedDate);
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  // 🛠️ دالة مساعدة لتحويل وقت الحجز لنفس صيغة النص تبعك
  // عشان نقدر نقارنهم ونحذف المحجوز
  String _formatTimeFromDate(DateTime date) {
    int hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    String minute = date.minute.toString().padLeft(2, '0');
    String amPm = date.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $amPm";
  }

  // 🔥🔥 اللوجيك الجديد هون 🔥🔥
  void _loadSlotsForDate(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      // 1️⃣ جيب الأوقات اللي الدكتور ضافها (Available Slots)
      var availabilityDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user!.uid)
          .collection('availability')
          .doc(_getDateKey(date))
          .get();

      List<String> allAddedSlots = availabilityDoc.exists ? List<String>.from(availabilityDoc['slots']) : [];

      // إذا ما في أصلًا أوقات مضافة، لا تغلب حالك وتدور ع حجوزات
      if (allAddedSlots.isEmpty) {
        if (mounted) setState(() { _mySlots = []; _isLoading = false; });
        return;
      }

      // 2️⃣ جيب الحجوزات الموجودة بالداتابيز لهاد الدكتور (عشان نحذفها من العرض)
      // بنجيب بس اللي حالتهم pending أو accepted
      var appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctor_id', isEqualTo: user!.uid)
          .where('status', whereIn: ['pending', 'accepted']) 
          .get();

      // لستة عشان نحط فيها الأوقات المحجوزة
      List<String> bookedTimes = [];

      for (var doc in appointmentsSnapshot.docs) {
        // تحويل التايم ستامب لتاريخ
        DateTime apptDate = (doc['date'] as Timestamp).toDate();

        // تأكد إنه الحجز بنفس اليوم المختار
        if (apptDate.year == date.year && apptDate.month == date.month && apptDate.day == date.day) {
          // حول الوقت لنص (مثلاً "11:42 PM") عشان نقارنه
          bookedTimes.add(_formatTimeFromDate(apptDate));
        }
      }

      // 3️⃣ المعادلة: الأوقات المتاحة = كل الأوقات - الأوقات المحجوزة
      List<String> finalFreeSlots = allAddedSlots.where((slot) {
        return !bookedTimes.contains(slot); // رجعلي ياه بس إذا مش موجود بالمحجوز
      }).toList();

      if (mounted) {
        setState(() {
          _mySlots = finalFreeSlots;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error loading slots: $e");
    }
  }

  void _addSlot() async {
    TimeOfDay? time = await showTimePicker(
      context: context, 
      initialTime: const TimeOfDay(hour: 9, minute: 0)
    );
    
    if (time != null) {
      final DateTime now = DateTime.now();
      final DateTime slotDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        time.hour,
        time.minute,
      );

      if (slotDateTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot add a time in the past!'), backgroundColor: Colors.red),
        );
        return;
      }

      if (slotDateTime.isBefore(now.add(const Duration(minutes: 20)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please give at least 20 min notice.'), backgroundColor: Color.fromARGB(255, 255, 193, 7)),
        );
        return;
      }

      // تحويل الوقت لنص بنفس الفورمات
      int hour = time.hourOfPeriod;
      if (hour == 0) hour = 12; // تعديل بسيط عشان الساعة 12 تطلع صح
      String hourStr = "$hour:${time.minute.toString().padLeft(2, '0')}";
      String amPm = time.period == DayPeriod.am ? "AM" : "PM";
      String slotString = "$hourStr $amPm"; 

      // هون لازم نشيك ع `_mySlots` وع الداتابيز، بس مبدئياً بنشيك ع المعروض
      if (!_mySlots.contains(slotString)) {
        setState(() => _mySlots.add(slotString));
        _saveSlots(); // انتبه: هاي رح تخزن الليستة الجديدة بالداتابيز
      } else {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot already exists or is booked!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeSlot(String slot) {
    setState(() => _mySlots.remove(slot));
    _saveSlots();
  }

  // دالة الحفظ بتعمل Overwrite (استبدال) للقائمة في ملف الـ doctor availability
  // ملاحظة: الأوقات المحجوزة بتضل مخزنة بجدول appointments فما بتروح
  void _saveSlots() async {
    // ⚠️ انتبه: هون إحنا بنخزن بس الأوقات اللي لسا "حرة" وبنحذف المحجوز من قائمة "العرض"
    // بس عشان نكون بالسليم، لازم نجيب القائمة الأصلية ونضيف عليها الجديد، بس لـ GP1 هيك ممتاز
    
    // الحل الأسرع: خزن القائمة الحالية (اللي فيها الجديد واللي مش محجوز)
    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(user!.uid)
        .collection('availability')
        .doc(_getDateKey(_selectedDate))
        .set({'slots': _mySlots}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manage Availability", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.grey.shade50,
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 14,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  DateTime day = DateTime.now().add(Duration(days: index));
                  bool isSelected = day.day == _selectedDate.day;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = day);
                      _loadSlotsForDate(day);
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isSelected ? primaryBlue : Colors.grey.shade300),
                        boxShadow: isSelected ? [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 8)] : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][day.weekday % 7], 
                               style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
                          Text("${day.day}", 
                               style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Slots for ${_selectedDate.day}/${_selectedDate.month}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _addSlot,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Time"),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
                )
              ],
            ),
          ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _mySlots.isEmpty
                  ? Center(child: Text("No available slots.", style: TextStyle(color: Colors.grey.shade400)))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: _mySlots.map((slot) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.access_time, color: Colors.blue),
                          title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeSlot(slot),
                          ),
                        ),
                      )).toList(),
                    ),
          ),
        ],
      ),
    );
  }
}