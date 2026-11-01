import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class CommsService {
  /// Initiates a masked phone call via Twilio backend proxy
  /// and opens the device phone dialer automatically.
  static Future<bool> initiateCall({
    required BuildContext context,
    required String callerPhone,
    required String receiverPhone,
    required String bookingId,
  }) async {
    try {
      // 1. Request virtual proxy channel from backend
      final response = await http.post(
        Uri.parse(ApiConfig.maskedCall),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'callerPhone': callerPhone,
          'receiverPhone': receiverPhone,
          'bookingId': bookingId,
        }),
      );

      String numberToDial = receiverPhone.isNotEmpty ? receiverPhone : '18005550199';

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['proxyNumber'] != null) {
          numberToDial = data['proxyNumber'];
        } else if (data['virtualProxyNumber'] != null) {
          numberToDial = data['virtualProxyNumber'];
        }
      }

      // 2. Format phone URI and launch phone dialer
      final Uri telUri = Uri(scheme: 'tel', path: numberToDial);

      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Fallback launch
        await launchUrl(Uri.parse('tel:$numberToDial'), mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('Error initiating call: $e');
      // Direct call fallback
      final fallbackNum = receiverPhone.isNotEmpty ? receiverPhone : '9876543210';
      try {
        final Uri telUri = Uri(scheme: 'tel', path: fallbackNum);
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
        return true;
      } catch (err) {
        debugPrint('Fallback dialer error: $err');
      }
    }
    return false;
  }
}
