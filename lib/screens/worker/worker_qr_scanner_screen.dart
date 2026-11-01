import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';

class WorkerQrScannerScreen extends StatefulWidget {
  const WorkerQrScannerScreen({super.key});

  @override
  State<WorkerQrScannerScreen> createState() => _WorkerQrScannerScreenState();
}

class _WorkerQrScannerScreenState extends State<WorkerQrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  final TextEditingController _manualTokenController = TextEditingController();

  @override
  void dispose() {
    _scannerController.dispose();
    _manualTokenController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeScanned(String rawToken) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final bookingService = Provider.of<BookingService>(context, listen: false);

    final result = await bookingService.verifyQRToken(
      qrToken: rawToken,
      workerId: authService.currentUser?.id ?? '',
      token: authService.token ?? '',
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Service Started Successfully!'),
          backgroundColor: AppConstants.successColor,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to verify QR code'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showManualTokenDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
        title: const Text('Enter Arrival Code', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 6-digit Arrival Code shown on the Customer Verification sheet:',
              style: TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualTokenController,
              decoration: const InputDecoration(
                labelText: 'Manual Arrival Code / Token',
                hintText: 'e.g. 285748',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            onPressed: () {
              final text = _manualTokenController.text.trim();
              Navigator.pop(ctx);
              if (text.isNotEmpty) {
                _handleBarcodeScanned(text);
              }
            },
            child: const Text('Verify & Start', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Customer QR Code'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimaryColor,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _handleBarcodeScanned(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Scanner Overlay Mask
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppConstants.primaryColor, width: 3),
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Align the Customer\'s QR Code within the box',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppConstants.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _showManualTokenDialog,
                  icon: const Icon(Icons.keyboard, color: AppConstants.primaryColor),
                  label: const Text(
                    'Enter Code Manually',
                    style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Verifying QR Token...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
