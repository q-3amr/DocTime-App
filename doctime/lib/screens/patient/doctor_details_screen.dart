import 'package:flutter/material.dart';

class DoctorDetailsScreen extends StatefulWidget {
  // بنستقبل بيانات الدكتور (حالياً دمي داتا)
  final String doctorName;
  final String specialty;

  const DoctorDetailsScreen({
    super.key, 
    required this.doctorName, 
    required this.specialty
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  // أوقات وهمية للعرض فقط
  final List<String> timeSlots = ["10:00 AM", "11:00 AM", "02:00 PM", "04:30 PM"];
  int selectedTimeIndex = -1; // عشان نعرف أي وقت اختار

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Doctor Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Doctor Card Info
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.person, size: 40, color: Color(0xFF407CE2)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dr. ${widget.doctorName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(widget.specialty, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 5),
                            Text("4.8 (Reviews)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 2. About Doctor
            const Text("About Doctor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "Dr. ${widget.doctorName} is a top specialist in ${widget.specialty} at Jordan University Hospital. He has over 10 years of experience in treating complex cases.",
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),

            const SizedBox(height: 25),

            // 3. Schedules (UI Only)
            const Text("Available Slots", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(timeSlots.length, (index) {
                return ChoiceChip(
                  label: Text(timeSlots[index]),
                  selected: selectedTimeIndex == index,
                  selectedColor: const Color(0xFF407CE2),
                  labelStyle: TextStyle(color: selectedTimeIndex == index ? Colors.white : Colors.black),
                  onSelected: (bool selected) {
                    setState(() {
                      selectedTimeIndex = selected ? index : -1;
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),

      // 4. Booking Button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            // هون رح نضيف كود الحجز بعدين
            if (selectedTimeIndex != -1) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Logic Coming Soon! 🚀")));
            } else {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a time first")));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF407CE2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Book Appointment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}