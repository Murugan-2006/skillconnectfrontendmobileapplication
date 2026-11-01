class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'customer', 'worker', 'admin'
  final String street;
  final String district;
  final String taluk;
  final String city;
  final String skill;
  final String fcmToken;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.street,
    required this.district,
    required this.taluk,
    required this.city,
    this.skill = '',
    this.fcmToken = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      street: address?['street'] ?? '',
      district: address?['district'] ?? '',
      taluk: address?['taluk'] ?? '',
      city: address?['city'] ?? '',
      skill: json['skill'] ?? '',
      fcmToken: json['fcmToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'address': {
        'street': street,
        'district': district,
        'taluk': taluk,
        'city': city,
      },
      'skill': skill,
      'fcmToken': fcmToken,
    };
  }
}
