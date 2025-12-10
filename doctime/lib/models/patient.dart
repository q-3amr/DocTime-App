class PatientModel {
  final String uid;
  final String email;
  final String name;
  final String role; // رح تكون دائماً "patient"
  final String? profileImage; // عشان لقدام بس يحط صورة

  PatientModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage,
  });

  // 1. تحويل البيانات لـ Map (عشان نرفعها عالفايربيس)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'profileImage': profileImage ?? '', // إذا ما في صورة بنبعث نص فاضي
    };
  }

  // 2. قراءة البيانات من الفايربيس (عشان نعرضها بالتطبيق)
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