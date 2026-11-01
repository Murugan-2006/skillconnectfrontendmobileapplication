import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../services/socket_service.dart';

class RequestingScreen extends StatefulWidget {
  const RequestingScreen({super.key});

  @override
  State<RequestingScreen> createState() => _RequestingScreenState();
}

class _RequestingScreenState extends State<RequestingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Clear any previous accepted booking in SocketService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SocketService>(context, listen: false).clearAcceptedBooking();
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String serviceName = arguments['service'] ?? 'Service';

    // Check if worker accepted
    if (socketService.acceptedBooking != null) {
      final booking = socketService.acceptedBooking!;
      final workerName = booking['workerId']?['name'] ?? 'A provider';

      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppConstants.successColor,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Request Accepted!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$workerName has accepted your request for $serviceName.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppConstants.textSecondaryColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  onPressed: () {
                    socketService.clearAcceptedBooking();
                    Navigator.popUntil(context, ModalRoute.withName('/customer-home'));
                  },
                  child: const Text(
                    'Go to Dashboard',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing Radar Rings
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120 + (_animationController.value * 80),
                        height: 120 + (_animationController.value * 80),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.15 * (1 - _animationController.value)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 80 + (_animationController.value * 40),
                        height: 80 + (_animationController.value * 40),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.3 * (1 - _animationController.value)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              Text(
                'Finding Your $serviceName...',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Broadcasting request to nearby available professionals...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppConstants.textSecondaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              // Cancel Button
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  foregroundColor: AppConstants.errorColor,
                ),
                icon: const Icon(Icons.close_rounded),
                label: const Text(
                  'Cancel Request',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
