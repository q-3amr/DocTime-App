import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/star_rating_widget.dart';
import '../common/chat_screen.dart';
import '../auth/login_screen.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String? doctorId;
  final double? latitude;
  final double? longitude;
  final double? distance;

  const DoctorDetailsScreen({
    super.key,
    required this.doctorName,
    required this.specialty,
    this.doctorId,
    this.latitude,
    this.longitude,
    this.distance,
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final _db = DatabaseService();
  final User? user = FirebaseAuth.instance.currentUser;

  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _generateSlotsForDate(_selectedDate);
  }

  Future<void> _openDirections() async {
    if (widget.latitude != null && widget.longitude != null) {
      final Uri googleMapsUrl = Uri.parse(
          'google.navigation:q=${widget.latitude},${widget.longitude}&mode=d');

      try {
        if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl);
        } else {
          final Uri webUrl = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}');
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open maps')),
          );
        }
      }
    }
  }

  void _generateSlotsForDate(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeSlot = null;
    });

    final dateKey = formatDateKey(date);

    final availabilityDoc = await _db.getAvailability(
      widget.doctorId ?? '',
      dateKey,
    );

    if (!availabilityDoc.exists || availabilityDoc['slots'] == null) {
      if (mounted) {
        setState(() {
          _availableSlots = [];
          _isLoadingSlots = false;
        });
      }
      return;
    }

    final List<String> doctorSlots = List<String>.from(
      availabilityDoc['slots'],
    );

    final appointmentsSnap = await _db.getAppointmentsForDoctor(
      widget.doctorId ?? '',
    );

    final Set<String> takenTimes = {};
    for (var doc in appointmentsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final DateTime apptDate = parseDate(data['date']);

      if (apptDate.year == date.year &&
          apptDate.month == date.month &&
          apptDate.day == date.day) {
        if (data['status'] != 'cancelled' && data['status'] != 'rejected') {
          takenTimes.add(formatTimeFromDateTime(apptDate));
        }
      }
    }

    final available =
        doctorSlots.where((s) => !takenTimes.contains(s)).toList();

    if (mounted) {
      setState(() {
        _availableSlots = available;
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
        const SnackBar(content: Text('Please select a time slot first!')),
      );
      return;
    }

    final parts = _selectedTimeSlot!.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    if (parts[1] == 'PM' && hour != 12) hour += 12;
    if (parts[1] == 'AM' && hour == 12) hour = 0;

    final finalDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    try {
      final patient = await _db.getUserById(user!.uid);
      final patientName = patient?.name ?? 'Unknown';

      final newAppointment = AppointmentModel(
        id: '',
        doctorId: widget.doctorId ?? '',
        doctorName: widget.doctorName,
        patientId: user!.uid,
        patientName: patientName,
        appointmentDateTime: finalDate,
        status: 'pending',
      );

      final success = await _db.bookAppointmentSafely(newAppointment);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request Sent! Wait for approval.')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Sorry, this slot was just booked by someone else!'),
              backgroundColor: Colors.red,
            ),
          );
          _generateSlotsForDate(_selectedDate);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
          'Please login to book an appointment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
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
            backgroundColor: kPrimaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: kPrimaryBlue.withValues(alpha: 0.8),
                child: const Icon(Icons.person, size: 100, color: Colors.white),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dr. ${widget.doctorName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _openDirections,
                    child: const Icon(Icons.location_on,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
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
                  const SizedBox(height: 15),
                  StreamBuilder<UserModel?>(
                    stream: widget.doctorId != null
                        ? _db.streamUser(widget.doctorId!)
                        : null,
                    builder: (context, snap) {
                      double avg = snap.data?.rating ?? 0.0;
                      int count = snap.data?.reviewCount ?? 0;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (avg > 0) ...[
                                StarRatingWidget(
                                  initialRating: avg,
                                  starSize: 20,
                                  isReadOnly: true,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${avg.toStringAsFixed(1)}  ($count ${count == 1 ? 'Review' : 'Reviews'})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ] else
                                const Text(
                                  'No reviews yet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          if (widget.distance != null)
                            Text(
                              '${widget.distance!.toStringAsFixed(1)} km away',
                              style: const TextStyle(
                                color: kPrimaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openDirections,
                      icon: const Icon(Icons.map_outlined, color: kPrimaryBlue),
                      label: const Text(
                        'Show me the directions',
                        style: TextStyle(
                          color: kPrimaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue.withValues(alpha: 0.1),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                              color: kPrimaryBlue.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Select Date',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (context, index) {
                        final day = DateTime.now().add(Duration(days: index));
                        final isSelected = day.day == _selectedDate.day &&
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
                              color: isSelected ? kPrimaryBlue : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? kPrimaryBlue
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  [
                                    'Sun',
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                  ][day.weekday % 7],
                                  style: TextStyle(
                                    color:
                                        isSelected ? Colors.white : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${day.day}',
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
                    'Available Time Slots',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _isLoadingSlots
                      ? const Center(child: CircularProgressIndicator())
                      : _availableSlots.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No slots available for this day',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _availableSlots.map((slot) {
                                final isSelected = _selectedTimeSlot == slot;
                                return ChoiceChip(
                                  label: Text(slot),
                                  selected: isSelected,
                                  selectedColor: kPrimaryBlue,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  onSelected: (val) => setState(
                                    () => _selectedTimeSlot = val ? slot : null,
                                  ),
                                );
                              }).toList(),
                            ),
                  const SizedBox(height: 30),
                  const Text(
                    'Patient Reviews',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: widget.doctorId != null
                        ? _db.streamReviewsForDoctor(widget.doctorId!)
                        : null,
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final reviews = snap.data!.docs.where((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final r = (d['rating'] as num?)?.toDouble() ?? 0.0;
                        return r > 0;
                      }).toList();

                      if (reviews.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No reviews yet. Be the first!',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 14),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: reviews.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          final double r =
                              (d['rating'] as num?)?.toDouble() ?? 0.0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      d['patient_name'] ?? 'Patient',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    Row(
                                      children: [
                                        StarRatingWidget(
                                          initialRating: r,
                                          starSize: 16,
                                          isReadOnly: true,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          r.toStringAsFixed(1),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if ((d['feedback_text'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    d['feedback_text'],
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                        fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
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
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: kPrimaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: kPrimaryBlue,
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
                  onPressed:
                      _selectedTimeSlot == null ? null : _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Book Appointment',
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
