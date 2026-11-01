import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../services/socket_service.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/customer_qr_dialog.dart';
import '../../widgets/notifications_modal_sheet.dart';
import '../../widgets/worker_card.dart';
import 'live_tracking_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _searchController = TextEditingController();
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Electrician', 'icon': Icons.bolt},
    {'name': 'Plumber', 'icon': Icons.water_drop},
    {'name': 'AC Repair', 'icon': Icons.ac_unit},
    {'name': 'Electronic Repair', 'icon': Icons.electrical_services},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final socketService = Provider.of<SocketService>(context, listen: false);
      final aiService = Provider.of<AiService>(context, listen: false);
      final bookingService = Provider.of<BookingService>(context, listen: false);

      // Auto-connect socket if auto-logged in
      if (authService.currentUser != null) {
        if (!socketService.isConnected) {
          socketService.initSocket(
            authService.currentUser!.id,
            authService.currentUser!.role,
            authService.currentUser!.skill,
          );
        }
        bookingService.fetchBookings(authService.currentUser!.id, authService.token ?? '');
      }
      
      // 1. Fetch immediately so the screen is never blank
      aiService.fetchWorkersBySkill('');

      // 2. Fetch location in the background and sort by distance once resolved
      final locationService = LocationService();
      locationService.getCurrentLocation().then((position) {
        if (position != null && mounted) {
          aiService.fetchWorkersBySkill(
            '',
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final aiService = Provider.of<AiService>(context);
    final bookingService = Provider.of<BookingService>(context);
    final socketService = Provider.of<SocketService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final userName = authService.currentUser?.name ?? 'User';

    // Show real-time notification if a worker accepted the request
    if (socketService.acceptedBooking != null) {
      final bookingData = socketService.acceptedBooking!;
      final workerName = bookingData['workerId']?['name'] ?? 'A provider';
      final serviceName = bookingData['service'] ?? 'service';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        
        notificationService.addNotification(
          title: 'Request Accepted! 🎉',
          body: '$workerName accepted your request for $serviceName.',
          type: 'accepted',
          bookingData: bookingData,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 $workerName accepted your request for $serviceName!'),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 5),
          ),
        );
        if (authService.currentUser != null) {
          bookingService.fetchBookings(authService.currentUser!.id, authService.token ?? '');
        }
        socketService.clearAcceptedBooking();
      });
    }

    // Active accepted/in-progress bookings for customer
    final activeBookings = bookingService.bookings.where(
      (b) => b.status == 'Accepted' || b.status == 'InProgress',
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: RefreshIndicator(
        color: AppConstants.primaryColor,
        onRefresh: () async {
          await aiService.fetchWorkersBySkill('');
        },
        child: CustomScrollView(
        slivers: [
          // 1. Vibrant Modern Gradient Hero Header
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 45),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF005F56), Color(0xFF00897B), Color(0xFF004D40)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Location Pill + Notification & Logout
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.my_location_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Your Location (GPS)',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => const NotificationsModalSheet(),
                                      );
                                    },
                                  ),
                                  if (notificationService.unreadCount > 0)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Text(
                                          '${notificationService.unreadCount}',
                                          style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                                onPressed: () async {
                                  await authService.logout();
                                  if (context.mounted) {
                                    Navigator.pushReplacementNamed(context, '/login');
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // User Greeting Banner
                      Text(
                        'Hello, $userName! 👋',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find trusted verified service experts near you',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // Floating Glassmorphic Search Bar overlapping Header
                Positioned(
                  bottom: -24,
                  left: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for services, e.g. Electrician, AC...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppConstants.primaryColor),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppConstants.primaryColor, size: 20),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Body Scroll Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Active Bookings Card Banner
                  if (activeBookings.isNotEmpty) ...[
                    Row(
                      children: const [
                        Icon(Icons.shield_outlined, color: AppConstants.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Active Service Verification',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...activeBookings.map((b) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, AppConstants.primaryColor.withOpacity(0.03)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.4), width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user_outlined, color: AppConstants.primaryColor, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.service,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textPrimaryColor),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: b.status == 'InProgress' ? AppConstants.successColor : Colors.amber[700],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      b.status == 'Accepted' ? 'Provider En-Route' : 'Work In Progress ⚡',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: b.status == 'InProgress' ? AppConstants.successColor : Colors.amber[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LiveTrackingScreen(booking: b),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map_rounded, size: 16, color: Colors.white),
                                label: const Text('Track Map', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppConstants.primaryColor),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => CustomerQrDialog(booking: b),
                                  );
                                },
                                icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: AppConstants.primaryColor),
                                label: const Text('Show QR', style: TextStyle(color: AppConstants.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )).toList(),
                    const SizedBox(height: 20),
                  ],

                  // Popular Categories Header
                  const Text(
                    'Popular Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Grid / Carousel of Rich Colorful Category Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRichCategoryCard(
                        context,
                        title: 'Electrician',
                        icon: Icons.bolt_rounded,
                        bgColor: const Color(0xFFFFF8E1),
                        iconColor: const Color(0xFFFFB300),
                      ),
                      _buildRichCategoryCard(
                        context,
                        title: 'Plumber',
                        icon: Icons.water_drop_rounded,
                        bgColor: const Color(0xFFE1F5FE),
                        iconColor: const Color(0xFF0288D1),
                      ),
                      _buildRichCategoryCard(
                        context,
                        title: 'AC Repair',
                        icon: Icons.ac_unit_rounded,
                        bgColor: const Color(0xFFE0F2F1),
                        iconColor: const Color(0xFF00897B),
                      ),
                      _buildRichCategoryCard(
                        context,
                        title: 'Electronics',
                        icon: Icons.electrical_services_rounded,
                        bgColor: const Color(0xFFF3E5F5),
                        iconColor: const Color(0xFF8E24AA),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Recommended Workers Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Service Providers Nearby',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  aiService.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(30.0),
                          child: Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
                        )
                      : aiService.workers.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.withOpacity(0.12)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.sensors_off_rounded, size: 44, color: AppConstants.primaryColor),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No providers loaded yet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppConstants.textSecondaryColor, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppConstants.primaryColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      aiService.fetchWorkersBySkill('');
                                    },
                                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                                    label: const Text(
                                      'Refresh Nearby Providers',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: aiService.workers.length,
                              itemBuilder: (context, index) {
                                final worker = aiService.workers[index];
                                return WorkerCard(
                                  worker: worker,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/worker-details',
                                      arguments: worker,
                                    );
                                  },
                                );
                              },
                            ),
                  const SizedBox(height: 80), // Bottom padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF005F56), Color(0xFF00897B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00897B).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          backgroundColor: Colors.transparent,
          icon: const Icon(Icons.auto_awesome, color: Colors.amber),
          label: const Text(
            'AI Assistant',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _showAiAssistantDialog(context),
        ),
      ),
    );
  }

  Widget _buildRichCategoryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/worker-list',
          arguments: title == 'Electronics' ? 'Electronic Repair' : title,
        );
      },
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showAiAssistantDialog(BuildContext context) {
    final aiService = Provider.of<AiService>(context, listen: false);
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'AI Service Assistant',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Describe your issue (e.g. "My sink is leaking")',
                    style: TextStyle(color: AppConstants.textSecondaryColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Enter your query...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (aiService.assistantReply.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryLightColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      child: Text(
                        aiService.assistantReply,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  aiService.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            ),
                          ),
                          onPressed: () async {
                            await aiService.queryAssistant(textController.text);
                            setStateSheet(() {});
                          },
                          child: const Text('Ask AI', style: TextStyle(color: Colors.white)),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
