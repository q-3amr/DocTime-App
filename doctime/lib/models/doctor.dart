class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final String imageUrl;
  final double rating;
  final String location;
  final String about;
  final bool isVerified; // to make sure that the doctor is verified

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
    required this.rating,
    required this.location,
    required this.about,
    this.isVerified = false,
  });

  // من Firebase ➜ إلى الموديل
  factory DoctorModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DoctorModel(
      id: documentId,
      name: map['name'] ?? '',
      specialty: map['specialty'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      location: map['location'] ?? '',
      about: map['about'] ?? '',
      isVerified: map['isVerified'] ?? false,
    );
  }

  // من الموديل ➜ إلى Map نخزنها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'imageUrl': imageUrl,
      'rating': rating,
      'location': location,
      'about': about,
      'isVerified': isVerified,
    };
  }
}
