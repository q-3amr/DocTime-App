class AppointmentModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? notes; //patient notes for the appointment

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.status,
    this.notes,
  });

  // من Firebase للتطبيق
  factory AppointmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AppointmentModel(
      id: documentId,
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? 'Unknown',
      dateTime: DateTime.parse(map['dateTime']), // convert from text to DateTime
      status: map['status'] ?? 'pending',
      notes: map['notes'],
    );
  }

  // من التطبيق لـ Firebase
  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'dateTime': dateTime.toIso8601String(), // store the date as text
      'notes': notes,
    };
  }
}