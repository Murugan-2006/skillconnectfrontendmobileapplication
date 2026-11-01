class BookingModel {
  final String id;
  final String customerId;
  final String workerId;
  final String service;
  final String status; // 'Pending', 'Accepted', 'InProgress', 'Completed', 'Rejected'
  final DateTime date;
  final DateTime? startTime;
  final String? qrToken;
  final DateTime? qrExpiresAt;
  final String? completionOtp;
  final double? receivedAmount;
  final double? latitude;
  final double? longitude;
  final String? description;
  final List<String>? problemImages;
  final String? problemVideo;

  BookingModel({
    required this.id,
    required this.customerId,
    required this.workerId,
    required this.service,
    required this.status,
    required this.date,
    this.startTime,
    this.qrToken,
    this.qrExpiresAt,
    this.completionOtp,
    this.receivedAmount,
    this.latitude,
    this.longitude,
    this.description,
    this.problemImages,
    this.problemVideo,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? json['id'] ?? '',
      customerId: json['customerId'] is Map ? json['customerId']['_id'] ?? '' : json['customerId'] ?? '',
      workerId: json['workerId'] is Map ? json['workerId']['_id'] ?? '' : json['workerId'] ?? '',
      service: json['service'] ?? '',
      status: json['status'] ?? 'Pending',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      qrToken: json['qrToken'],
      qrExpiresAt: json['qrExpiresAt'] != null ? DateTime.parse(json['qrExpiresAt']) : null,
      completionOtp: json['completionOtp'],
      receivedAmount: (json['receivedAmount'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'],
      problemImages: json['problemImages'] != null ? List<String>.from(json['problemImages']) : null,
      problemVideo: json['problemVideo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'workerId': workerId,
      'service': service,
      'status': status,
      'date': date.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'qrToken': qrToken,
      'qrExpiresAt': qrExpiresAt?.toIso8601String(),
      'completionOtp': completionOtp,
      'receivedAmount': receivedAmount,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'problemImages': problemImages,
      'problemVideo': problemVideo,
    };
  }
}
