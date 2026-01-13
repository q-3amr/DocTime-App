class AppointmentModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final DateTime appointmentDateTime;
  final String status;
  final String? notes;

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
      ),
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
          .toIso8601String(),
      'notes': notes,
    };
  }
}
