import 'package:flutter/foundation.dart';

class ApiConfig {
  // Deployed Render backend URL
  static const String _deployedUrl = 'https://skillconnectbackend-1.onrender.com/api';
  static const String _wifiUrl = 'http://172.19.9.72:5000/api';
  static const String _localUrl = 'http://127.0.0.1:5000/api';

  // Uses live 24/7 Render cloud backend
  static String get baseUrl {
    return _deployedUrl;
  }

  // Auth Routes
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get getProfile => '$baseUrl/auth/profile';
  static String get sendOtp => '$baseUrl/auth/send-otp';
  static String get updateFcmToken => '$baseUrl/auth/fcm-token';

  // Worker Routes
  static String get getWorkers => '$baseUrl/workers';
  static String get getWorkerDetails => '$baseUrl/workers';
  static String get updateWorkerProfile => '$baseUrl/workers/profile';

  // Booking Routes
  static String get bookings => '$baseUrl/bookings';
  static String get getBookings => '$baseUrl/bookings/user';
  static String getBookingQrToken(String bookingId) => '$baseUrl/bookings/$bookingId/qr-token';
  static String get verifyBookingQr => '$baseUrl/bookings/verify-qr';

  // Upload Route
  static String get upload => '$baseUrl/upload';

  // Comms Routes
  static String get maskedCall => '$baseUrl/comms/masked-call';
  static String get maskedMessage => '$baseUrl/comms/masked-message';

  // Review Routes
  static String get reviews => '$baseUrl/reviews';

  // AI Routes
  static String get aiRecommend => '$baseUrl/services/ai-recommendation';
  static String get aiChat => '$baseUrl/services/ai-assistant';

  /// Resolves local media URLs to match current backend host
  static String resolveUrl(String url) {
    if (url.startsWith('http://localhost:5000') || url.startsWith('http://127.0.0.1:5000') || url.startsWith('http://10.0.2.2:5000')) {
      final baseHost = baseUrl.replaceAll('/api', '');
      return url
          .replaceAll('http://localhost:5000', baseHost)
          .replaceAll('http://127.0.0.1:5000', baseHost)
          .replaceAll('http://10.0.2.2:5000', baseHost);
    }
    return url;
  }
}
