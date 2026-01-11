import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/chat_screen.dart';
import '../auth/login_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String? doctorId;

  const DoctorDetailsScreen({
    super.key,
    required this.doctorName,
    required this.specialty,
    this.doctorId,
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color primaryBlue = const Color(0xFF407CE2);

  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _generateSlotsForDate(_selectedDate);
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  void _generateSlotsForDate(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeSlot = null;
    });

    List<String> availableSlots = [];

    var availabilityDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.doctorId)
        .collection('availability')
        .doc(_getDateKey(date))
        .get();

    if (!availabilityDoc.exists || availabilityDoc['slots'] == null) {
      if (mounted) {
        setState(() {
          _availableSlots = [];
          _isLoadingSlots = false;
        });
      }
      return;
    }

    List<String> doctorSlots = List<String>.from(availabilityDoc['slots']);

    var appointmentsSnap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctor_id', isEqualTo: widget.doctorId)
        .get();

    Set<String> takenTimes = {};
    for (var doc in appointmentsSnap.docs) {
      DateTime apptDate;
      var rawDate = doc['date'];

      if (rawDate is Timestamp) {
        apptDate = rawDate.toDate();
      } else if (rawDate is String) {
        apptDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      } else {
        continue;
      }

      if (apptDate.year == date.year &&
          apptDate.month == date.month &&
          apptDate.day == date.day) {
        if (doc['status'] != 'cancelled' && doc['status'] != 'rejected') {
          String hourStr =
              "${apptDate.hour > 12 ? apptDate.hour - 12 : (apptDate.hour == 0 ? 12 : apptDate.hour)}";
          String minuteStr = apptDate.minute == 0 ? "00" : "${apptDate.minute}";
          String amPm = apptDate.hour >= 12 ? "PM" : "AM";
          takenTimes.add("$hourStr:$minuteStr $amPm");
        }
      }
    }
    for (String slot in doctorSlots) {
      if (!takenTimes.contains(slot)) {
        availableSlots.add(slot);
      }
    }

    if (mounted) {
      setState(() {
        _availableSlots = availableSlots;
        _isLoadingSlots = false;
      });
    }
  }

  void _bookAppointment() async {
    if (user == null) {
      _showLoginDialog();
      return;
    }

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a time slot first!")),
      );
      return;
    }

    List<String> parts = _selectedTimeSlot!.split(' ');
    List<String> timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    if (parts[1] == "PM" && hour != 12) hour += 12;
    if (parts[1] == "AM" && hour == 12) hour = 0;

    DateTime finalDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      String patientName = userDoc.exists ? userDoc['name'] : "Unknown";

      await FirebaseFirestore.instance.collection('appointments').add({
        'doctor_id': widget.doctorId,
        'doctor_name': widget.doctorName,
        'patient_id': user?.uid,
        'patient_name': patientName,
        'date': finalDate,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request Sent! Wait for approval.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Required"),
        content: const Text(
          "Please login to book an appointment. You can browse doctors without an account, but booking requires login.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: primaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: primaryBlue.withOpacity(0.8),
                child: const Icon(Icons.person, size: 100, color: Colors.white),
              ),
              title: Text(
                "Dr. ${widget.doctorName}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.specialty,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 5),
                      const Text(
                        "4.8 (120 Reviews)",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Select Date",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (context, index) {
                        DateTime day = DateTime.now().add(
                          Duration(days: index),
                        );
                        bool isSelected =
                            day.day == _selectedDate.day &&
                            day.month == _selectedDate.month;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedDate = day);
                            _generateSlotsForDate(day);
                          },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryBlue : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? primaryBlue
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  [
                                    "Sun",
                                    "Mon",
                                    "Tue",
                                    "Wed",
                                    "Thu",
                                    "Fri",
                                    "Sat",
                                  ][day.weekday % 7],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${day.day}",
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Available Time Slots",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  _isLoadingSlots
                      ? const Center(child: CircularProgressIndicator())
                      : _availableSlots.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "No slots available for this day",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _availableSlots.map((slot) {
                            bool isSelected = _selectedTimeSlot == slot;
                            return ChoiceChip(
                              label: Text(slot),
                              selected: isSelected,
                              selectedColor: primaryBlue,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                              onSelected: (val) => setState(
                                () => _selectedTimeSlot = val ? slot : null,
                              ),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: primaryBlue,
                ),
                onPressed: () {
                  if (user == null) {
                    _showLoginDialog();
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ChatScreen(
                        receiverId: widget.doctorId!,
                        receiverName: widget.doctorName,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedTimeSlot == null
                      ? null
                      : _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Book Appointment",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
