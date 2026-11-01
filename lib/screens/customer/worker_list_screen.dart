import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../widgets/worker_card.dart';
import 'describe_problem_screen.dart';

class WorkerListScreen extends StatefulWidget {
  final String category;

  const WorkerListScreen({super.key, required this.category});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiService = Provider.of<AiService>(context, listen: false);

      // 1. Fetch immediately so the screen is never blank
      aiService.fetchWorkersBySkill(widget.category);

      // 2. Fetch location in the background and sort by distance once resolved
      final locationService = LocationService();
      locationService.getCurrentLocation().then((position) {
        if (position != null && mounted) {
          aiService.fetchWorkersBySkill(
            widget.category,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      });
    });
  }

  void _handleBroadcastBooking() {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a request')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DescribeProblemScreen(category: widget.category, isBroadcast: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiService = Provider.of<AiService>(context);

    final catLower = widget.category.toLowerCase();
    String? bgImagePath;
    if (catLower.contains('electrician')) {
      bgImagePath = 'assets/images/electrician_bg.jpg';
    } else if (catLower.contains('electronic')) {
      bgImagePath = 'assets/images/electronic_bg.jpg';
    } else if (catLower.contains('plumber')) {
      bgImagePath = 'assets/images/plumber_bg.jpg';
    } else if (catLower.contains('ac') ||
        catLower.contains('air conditioning') ||
        catLower.contains('air conditioner')) {
      bgImagePath = 'assets/images/ac_bg.jpg';
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          '${widget.category}s Near You',
          style: const TextStyle(
            color: AppConstants.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppConstants.textPrimaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Dynamic Category Background Image
          if (bgImagePath != null) ...[
            Positioned.fill(child: Image.asset(bgImagePath, fit: BoxFit.cover)),
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ],
          // Main Page Content
          aiService.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
                )
              : aiService.workers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      decoration: bgImagePath != null
                          ? BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            )
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${widget.category}s Registered Yet',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'We couldn\'t find any service providers registered in this category.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: aiService.workers.length,
                  itemBuilder: (context, index) {
                    final worker = aiService.workers[index];
                    return WorkerCard(
                      worker: worker,
                      onTap: () {
                        debugPrint(
                          'Navigating to worker-details with: ${worker.toJson()}',
                        );
                        Navigator.pushNamed(
                          context,
                          '/worker-details',
                          arguments: worker,
                        );
                      },
                    );
                  },
                ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
          icon: const Icon(Icons.flash_on, color: Colors.white),
          label: Text(
            'Request Quick Broadcast to All ${widget.category}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: _handleBroadcastBooking,
        ),
      ),
    );
  }
}
