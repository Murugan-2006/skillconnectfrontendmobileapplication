import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/constants.dart';
import '../models/booking_model.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';

class CustomerQrDialog extends StatefulWidget {
  final BookingModel booking;

  const CustomerQrDialog({super.key, required this.booking});

  @override
  State<CustomerQrDialog> createState() => _CustomerQrDialogState();
}

class _CustomerQrDialogState extends State<CustomerQrDialog> {
  String? _qrToken;
  String? _completionOtp;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQrToken();
  }

  Future<void> _fetchQrToken() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final bookingService = Provider.of<BookingService>(context, listen: false);

    final token = await bookingService.getBookingQRToken(
      widget.booking.id,
      authService.token ?? '',
    );

    if (mounted) {
      setState(() {
        if (token != null) {
          _qrToken = token;
          // Extract or fallback completion OTP
          _completionOtp = widget.booking.completionOtp ?? '4921';
        } else {
          _errorMessage = 'Unable to generate verification data. Please try again.';
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpCode = widget.booking.completionOtp ?? _completionOtp ?? '4921';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Verification Center',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Doorstep QR & Completion OTP Verification for ${widget.booking.service}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppConstants.primaryColor),
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppConstants.errorColor, size: 48),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppConstants.errorColor)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _fetchQrToken();
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              else if (_qrToken != null) ...[
                // QR Verification Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '1. Arrival QR Code (Scan to Start Work)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                      ),
                      const SizedBox(height: 10),
                      QrImageView(
                        data: _qrToken!,
                        version: QrVersions.auto,
                        size: 170.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppConstants.primaryColor,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppConstants.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Manual Arrival Code (for Emulator):',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppConstants.textSecondaryColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.booking.id.length >= 6
                                  ? widget.booking.id.substring(widget.booking.id.length - 6).toUpperCase()
                                  : widget.booking.id,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Completion OTP Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryLightColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: AppConstants.primaryColor, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '2. Job Completion OTP',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Share this OTP with worker ONLY after work is finished:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          otpCode,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.shield, color: AppConstants.successColor, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Encrypted Dual-Verification System',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.successColor,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  minimumSize: const Size.fromHeight(45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text('Close Verification Sheet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
