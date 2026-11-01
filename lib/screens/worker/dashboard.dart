import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/socket_service.dart';
import '../../services/location_tracking_service.dart';
import '../../widgets/problem_details_view.dart';
import 'worker_qr_scanner_screen.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  bool _isAvailable = true;
  final LocationTrackingService _locationTrackingService = LocationTrackingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final socketService = Provider.of<SocketService>(context, listen: false);

      if (authService.currentUser != null) {
        bookingService.fetchBookings(authService.currentUser!.id, authService.token ?? '');
        
        if (!socketService.isConnected) {
          socketService.initSocket(
            authService.currentUser!.id,
            authService.currentUser!.role,
            authService.currentUser!.skill,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _locationTrackingService.stopTracking();
    super.dispose();
  }

  void _showCompletionOtpDialog(BuildContext context, BookingModel booking) {
    final otpController = TextEditingController();
    final amountController = TextEditingController();
    final authService = Provider.of<AuthService>(context, listen: false);
    final bookingService = Provider.of<BookingService>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
        title: const Text('Job Completion & Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ask the customer for their 4-digit Completion OTP code shown on their app screen:',
              style: TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Customer Completion OTP',
                hintText: 'e.g. 4921',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount Received (Cash / UPI ₹)',
                hintText: 'e.g. 650',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.successColor),
            onPressed: () async {
              final otp = otpController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (otp.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid 4-digit customer OTP')),
                );
                return;
              }

              final result = await bookingService.completeJobWithOTP(
                bookingId: booking.id,
                otp: otp,
                amountReceived: amount,
                token: authService.token ?? '',
              );

              if (ctx.mounted) Navigator.pop(ctx);

              if (mounted) {
                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Job Completed! ₹$amount recorded in Earnings Dashboard.'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                  bookingService.fetchBookings(authService.currentUser!.id, authService.token ?? '');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Invalid OTP code'),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm Completion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showQuotationDialog(BuildContext context, BookingModel booking) {
    final partsController = TextEditingController();
    final laborController = TextEditingController();
    final descController = TextEditingController();
    final authService = Provider.of<AuthService>(context, listen: false);
    final bookingService = Provider.of<BookingService>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
        title: const Text('Create Digital Quotation', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter transparent parts and labor costs after inspecting the problem:',
                style: TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Parts / Repair Description',
                  hintText: 'e.g. Fan Capacitor Replacement & Motor Rewiring',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: partsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Parts Cost (₹)',
                  hintText: 'e.g. 300',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: laborController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Labor / Service Fee (₹)',
                  hintText: 'e.g. 350',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            onPressed: () async {
              final pCost = double.tryParse(partsController.text.trim()) ?? 0.0;
              final lCost = double.tryParse(laborController.text.trim()) ?? 0.0;
              final desc = descController.text.trim();

              final success = await bookingService.submitQuotation(
                bookingId: booking.id,
                partsCost: pCost,
                laborCost: lCost,
                partsDescription: desc,
                token: authService.token ?? '',
              );

              if (ctx.mounted) Navigator.pop(ctx);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quotation for ₹${pCost + lCost} sent to customer for approval!'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to send quotation'),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Quotation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bookingService = Provider.of<BookingService>(context);
    final socketService = Provider.of<SocketService>(context);
    final userName = authService.currentUser?.name ?? 'Worker';

    // Calculate worker earnings genuinely from completed bookings
    final completedBookings = bookingService.bookings.where((b) => b.status == 'Completed').toList();
    final totalEarningsCalculated = completedBookings.fold<double>(
      0.0,
      (sum, b) => sum + (b.receivedAmount ?? 0.0),
    );

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Worker Dashboard',
          style: TextStyle(color: AppConstants.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppConstants.errorColor),
            onPressed: () async {
              socketService.disconnectSocket();
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with Availability Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $userName! 🛠️',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
                    ),
                    const SizedBox(height: 4),
                    const Text('Manage your services & active jobs.', style: TextStyle(color: AppConstants.textSecondaryColor)),
                  ],
                ),
                Switch.adaptive(
                  value: _isAvailable,
                  activeColor: AppConstants.successColor,
                  onChanged: (val) {
                    setState(() {
                      _isAvailable = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Availability Status Banner
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: _isAvailable ? AppConstants.successColor.withValues(alpha: 0.1) : AppConstants.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAvailable ? Icons.check_circle_outline : Icons.pause_circle_outline,
                    color: _isAvailable ? AppConstants.successColor : AppConstants.errorColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isAvailable ? '🟢 Open for Jobs' : '🔴 Offline / Busy',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isAvailable ? AppConstants.successColor : AppConstants.errorColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Worker Metrics Dashboard (Earnings & Completed Jobs)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.monetization_on, color: AppConstants.secondaryColor, size: 28),
                        const SizedBox(height: 12),
                        const Text('Total Earnings', style: TextStyle(color: AppConstants.textSecondaryColor, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('₹${totalEarningsCalculated.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: AppConstants.successColor, size: 28),
                        const SizedBox(height: 12),
                        const Text('Completed Jobs', style: TextStyle(color: AppConstants.textSecondaryColor, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('${completedBookings.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 28),
                        const SizedBox(height: 12),
                        const Text('Rating', style: TextStyle(color: AppConstants.textSecondaryColor, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(completedBookings.isEmpty ? 'New ✨' : '5.0 / 5.0', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Incoming Emergency & Instant Job Offers
            if (_isAvailable && socketService.bookingOffers.isNotEmpty) ...[
              const Text(
                'Incoming Job Requests 🚨',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.errorColor),
              ),
              const SizedBox(height: 12),
              ...socketService.bookingOffers.map((offer) {
                final bookingId = offer['bookingId'].toString();
                final service = offer['service'] ?? 'General Service';
                final isEmergency = offer['isEmergency'] == true;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: isEmergency ? AppConstants.errorColor : AppConstants.primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: (isEmergency ? AppConstants.errorColor : AppConstants.primaryColor).withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              service,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            isEmergency ? '🚨 EMERGENCY SOS' : 'NEW REQUEST',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isEmergency ? AppConstants.errorColor : AppConstants.primaryColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      ProblemDetailsView(
                        description: offer['description'],
                        images: offer['problemImages'] != null ? List<String>.from(offer['problemImages']) : null,
                        videoUrl: offer['problemVideo'],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppConstants.errorColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                ),
                              ),
                              onPressed: () {
                                socketService.removeOffer(bookingId);
                              },
                              child: const Text('Decline', style: TextStyle(color: AppConstants.errorColor)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.successColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                ),
                              ),
                              onPressed: () async {
                                final success = await bookingService.updateBookingStatus(
                                  bookingId,
                                  'Accepted',
                                  authService.token ?? '',
                                  workerId: authService.currentUser?.id,
                                );
                                if (context.mounted) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Job accepted successfully! En-route tracking started.'),
                                        backgroundColor: AppConstants.successColor,
                                      ),
                                    );
                                    final customerId = offer['customerId']?.toString() ?? '';
                                    _locationTrackingService.startWorkerTracking(
                                      bookingId: bookingId,
                                      customerId: customerId,
                                      socketService: socketService,
                                    );

                                    bookingService.fetchBookings(authService.currentUser!.id, authService.token ?? '');
                                    socketService.removeOffer(bookingId);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('This job has already been claimed by another provider.'),
                                        backgroundColor: AppConstants.errorColor,
                                      ),
                                    );
                                    socketService.removeOffer(bookingId);
                                  }
                                }
                              },
                              child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
            ],

            // Active / Assigned Jobs List
            const Text(
              'Your Assigned Jobs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
            ),
            const SizedBox(height: 12),
            bookingService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : bookingService.bookings.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'No active jobs listed yet.',
                          style: TextStyle(color: AppConstants.textSecondaryColor),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: bookingService.bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookingService.bookings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(booking.service, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: booking.status == 'Completed'
                                              ? AppConstants.successColor.withValues(alpha: 0.1)
                                              : AppConstants.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          booking.status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: booking.status == 'Completed'
                                                ? AppConstants.successColor
                                                : AppConstants.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ProblemDetailsView(
                                    description: booking.description,
                                    images: booking.problemImages,
                                    videoUrl: booking.problemVideo,
                                  ),
                                  const SizedBox(height: 12),
                                  // Action buttons based on job state
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (booking.status == 'Accepted' || booking.status == 'InProgress') ...[
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppConstants.primaryColor),
                                          ),
                                          onPressed: () => _showQuotationDialog(context, booking),
                                          icon: const Icon(Icons.receipt_long, size: 16, color: AppConstants.primaryColor),
                                          label: const Text('Create Quote', style: TextStyle(color: AppConstants.primaryColor, fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (booking.status == 'Accepted') ...[
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppConstants.primaryColor,
                                          ),
                                          onPressed: () async {
                                            final scanned = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const WorkerQrScannerScreen(),
                                              ),
                                            );
                                            if (scanned == true && context.mounted) {
                                              bookingService.fetchBookings(
                                                authService.currentUser!.id,
                                                authService.token ?? '',
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.qr_code_scanner, size: 16, color: Colors.white),
                                          label: const Text('Scan QR Code', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        ),
                                      ] else if (booking.status == 'InProgress') ...[
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppConstants.successColor,
                                          ),
                                          onPressed: () => _showCompletionOtpDialog(context, booking),
                                          icon: const Icon(Icons.lock_open, size: 16, color: Colors.white),
                                          label: const Text('Complete (Enter OTP)', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
