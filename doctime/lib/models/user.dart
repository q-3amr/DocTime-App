class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'doctor' or 'patient'
  final String? profileImage;
  final String? specialty;
  final double? rating;
  final String? location;
  final String? about;
  final bool? isVerified;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage,
    // Doctor fields
    this.specialty,
    this.rating,
    this.location,
    this.about,
    this.isVerified,
  });

  bool get isDoctor => role == 'doctor';
  bool get isPatient => role == 'patient';
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'patient',
      profileImage: map['profileImage'],
      // Doctor fields
      specialty: map['specialty'],
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      location: map['location'],
      about: map['about'],
      isVerified: map['isVerified'] ?? false,
    );
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'email': email,
      'name': name,
      'role': role,
      'profileImage': profileImage ?? '',
    };
    if (isDoctor) {
      map['specialty'] = specialty ?? '';
      map['rating'] = rating ?? 0.0;
      map['location'] = location ?? '';
      map['about'] = about ?? '';
      map['isVerified'] = isVerified ?? false;
    }

    return map;
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? profileImage,
    String? specialty,
    double? rating,
    String? location,
    String? about,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      specialty: specialty ?? this.specialty,
      rating: rating ?? this.rating,
      location: location ?? this.location,
      about: about ?? this.about,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
