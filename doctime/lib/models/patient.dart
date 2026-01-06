class PatientModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? profileImage;

  PatientModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'profileImage': profileImage ?? '',
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'patient',
      profileImage: map['profileImage'],
    );
  }
}