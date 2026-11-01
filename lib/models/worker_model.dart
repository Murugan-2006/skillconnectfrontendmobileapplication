class WorkerModel {
  final String id;
  final String name;
  final String skill;
  final String experience;
  final double rating;
  final double latitude;
  final double longitude;
  final String phone;

  WorkerModel({
    required this.id,
    required this.name,
    required this.skill,
    required this.experience,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.phone,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      skill: json['skill'] ?? '',
      experience: json['experience']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'skill': skill,
      'experience': experience,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
    };
  }
}
