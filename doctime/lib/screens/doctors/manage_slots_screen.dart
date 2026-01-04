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

  void _loadSlotsForDate(DateTime date) async {
    setState(() => _isLoading = true);
    var doc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(user!.uid)
        .collection('availability')
        .doc(_getDateKey(date))
        .get();

    if (mounted) {
      setState(() {
        _mySlots = doc.exists ? List<String>.from(doc['slots']) : [];
        _isLoading = false;
      });
    }
  }

  void _addSlot() async {
    TimeOfDay? time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (time != null) {
      String hourStr = "${time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')}";
      String amPm = time.period == DayPeriod.am ? "AM" : "PM";
      String slotString = "$hourStr $amPm"; // صيغة موحدة: 9:00 AM

      if (!_mySlots.contains(slotString)) {
        setState(() => _mySlots.add(slotString));
        _saveSlots();
      }
    }
  }

  void _removeSlot(String slot) {
    setState(() => _mySlots.remove(slot));
    _saveSlots();
  }

  void _saveSlots() async {
    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(user!.uid)
        .collection('availability')
        .doc(_getDateKey(_selectedDate))
        .set({'slots': _mySlots});
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
          // شريط التاريخ
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
                  ? Center(child: Text("No slots added for this day.", style: TextStyle(color: Colors.grey.shade400)))
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