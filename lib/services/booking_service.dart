import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/booking_model.dart';

class BookingService extends ChangeNotifier {
  List<BookingModel> _bookings = [];
  bool _isLoading = false;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;

  Future<bool> createBooking({
    required String customerId,
    String? workerId,
    required String service,
    required DateTime date,
    required String token,
    double? latitude,
    double? longitude,
    String? description,
    List<String>? problemImages,
    String? problemVideo,
    bool? isEmergency,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> requestBody = {
        'customerId': customerId,
        'service': service,
        'date': date.toIso8601String(),
        'latitude': latitude ?? 13.0827,
        'longitude': longitude ?? 80.2707,
        'description': description ?? 'No problem description provided',
        'problemImages': problemImages ?? [],
        'problemVideo': problemVideo,
        'isEmergency': isEmergency ?? false,
      };
      
      if (workerId != null) {
        requestBody['workerId'] = workerId;
      }

      final payloadStr = json.encode(requestBody);
      final headersMap = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      http.Response response;
      try {
        response = await http.post(
          Uri.parse(ApiConfig.bookings),
          headers: headersMap,
          body: payloadStr,
        ).timeout(const Duration(seconds: 10));
      } catch (primaryErr) {
        final altUrl = ApiConfig.bookings.contains('10.0.2.2')
            ? ApiConfig.bookings.replaceAll('10.0.2.2', 'localhost')
            : ApiConfig.bookings.replaceAll('localhost', '10.0.2.2');
        debugPrint('Primary booking API (${ApiConfig.bookings}) failed: $primaryErr. Retrying with $altUrl...');
        response = await http.post(
          Uri.parse(altUrl),
          headers: headersMap,
          body: payloadStr,
        ).timeout(const Duration(seconds: 10));
      }

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Create Booking Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchBookings(String userId, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getBookings}/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _bookings = responseData.map((b) => BookingModel.fromJson(b)).toList();
      }
    } catch (e) {
      debugPrint('Fetch Bookings Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateBookingStatus(String bookingId, String status, String token, {String? workerId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> bodyData = {'status': status};
      if (workerId != null) {
        bodyData['workerId'] = workerId;
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.bookings}/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bodyData),
      );

      if (response.statusCode == 200) {
        final index = _bookings.indexWhere((element) => element.id == bookingId);
        if (index != -1) {
          final oldBooking = _bookings[index];
          _bookings[index] = BookingModel(
            id: oldBooking.id,
            customerId: oldBooking.customerId,
            workerId: oldBooking.workerId,
            service: oldBooking.service,
            status: status,
            date: oldBooking.date,
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Update Booking Status Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<String?> getBookingQRToken(String bookingId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getBookingQrToken(bookingId)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['token'];
      }
    } catch (e) {
      debugPrint('Get Booking QR Token Error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> verifyQRToken({
    required String qrToken,
    required String workerId,
    required String token,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyBookingQr),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'token': qrToken,
          'workerId': workerId,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final updatedBooking = BookingModel.fromJson(data['booking']);
        final index = _bookings.indexWhere((b) => b.id == updatedBooking.id);
        if (index != -1) {
          _bookings[index] = updatedBooking;
        } else {
          _bookings.insert(0, updatedBooking);
        }

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': data['message'], 'booking': updatedBooking};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': data['message'] ?? 'Failed to verify QR code'};
      }
    } catch (e) {
      debugPrint('Verify QR Token Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': 'Network error verifying QR code'};
  }

  Future<Map<String, dynamic>> completeJobWithOTP({
    required String bookingId,
    required String otp,
    required double amountReceived,
    required String token,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.bookings}/$bookingId/complete-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'otp': otp,
          'amountReceived': amountReceived,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final updatedBooking = BookingModel.fromJson(data['booking']);
        final index = _bookings.indexWhere((b) => b.id == updatedBooking.id);
        if (index != -1) {
          _bookings[index] = updatedBooking;
        }
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': data['message'], 'booking': updatedBooking};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': data['message'] ?? 'Invalid OTP code'};
      }
    } catch (e) {
      debugPrint('Complete Job OTP Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': 'Connection error completing job'};
  }

  Future<bool> submitQuotation({
    required String bookingId,
    required double partsCost,
    required double laborCost,
    required String partsDescription,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.bookings}/$bookingId/quotation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'partsCost': partsCost,
          'laborCost': laborCost,
          'partsDescription': partsDescription,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Submit Quotation Error: $e');
    }
    return false;
  }
}
