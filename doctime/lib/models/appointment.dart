class AppointmentModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final DateTime appointmentDateTime;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? notes; //patient notes for the appointment

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.appointmentDateTime,
    required this.status,
    this.notes,
  });
  factory AppointmentModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return AppointmentModel(
      id: documentId,
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? 'Unknown',
      appointmentDateTime: DateTime.parse(
        map['dateTime'],
      ), // convert from text to DateTime
      status: map['status'] ?? 'pending',
      notes: map['notes'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'dateTime': appointmentDateTime
          .toIso8601String(), // store the date as text
      'notes': notes,
    };
  }
}
