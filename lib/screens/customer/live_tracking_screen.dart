import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/comms_service.dart';
import '../../services/location_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/customer_qr_dialog.dart';
import '../../widgets/rating_review_dialog.dart';

class LiveTrackingScreen extends StatefulWidget {
  final BookingModel booking;

  const LiveTrackingScreen({super.key, required this.booking});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? _workerLatLng;
  late LatLng _customerLatLng;
  SocketService? _socketService;

  @override
  void initState() {
    super.initState();
    
    // Check if coordinates were passed or if fallback was used
    final custLat = widget.booking.latitude;
    final custLng = widget.booking.longitude;

    if (custLat != null && custLat != 0.0 && custLat != 13.0827) {
      _customerLatLng = LatLng(custLat, custLng!);
      _workerLatLng = LatLng(custLat + 0.0015, custLng + 0.0015);
    } else {
      // Default initial coordinates
      _customerLatLng = const LatLng(13.0827, 80.2707);
      _workerLatLng = const LatLng(13.0842, 80.2722);

      // Fetch real GPS position of customer device asynchronously
      LocationService().getCurrentLocation().then((pos) {
        if (pos != null && mounted) {
          setState(() {
            _customerLatLng = LatLng(pos.latitude, pos.longitude);
            _workerLatLng = LatLng(pos.latitude + 0.0015, pos.longitude + 0.0015);
          });
          _fitMapBounds();
        }
      });
    }

    // Add socket listener safely after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _socketService = Provider.of<SocketService>(context, listen: false);
      _socketService?.addListener(_onSocketLocationUpdate);
      _fitMapBounds();
    });
  }

  @override
  void dispose() {
    _socketService?.removeListener(_onSocketLocationUpdate);
    super.dispose();
  }

  bool _hasShownReview = false;

  void _showRatingDialog() {
    if (!mounted) return;
    _hasShownReview = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RatingReviewDialog(
        booking: widget.booking,
        onSubmitted: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onSocketLocationUpdate() {
    if (!mounted || _socketService == null) return;

    // Check for job completion socket event
    if (!_hasShownReview && _socketService!.completedBooking != null) {
      final compData = _socketService!.completedBooking!;
      if (compData['_id'] == widget.booking.id || compData['id'] == widget.booking.id) {
        _showRatingDialog();
        return;
      }
    }
    
    final data = _socketService!.latestWorkerLocation;
    if (data != null && data['bookingId'] == widget.booking.id && data['latitude'] != null) {
      final rawLat = (data['latitude'] as num).toDouble();
      final rawLng = (data['longitude'] as num).toDouble();

      // Calculate distance between customer and raw worker coordinates
      final rawDist = const Distance().distance(_customerLatLng, LatLng(rawLat, rawLng));
      
      LatLng normalizedWorkerLoc;
      // If distance > 50km (e.g., Android Emulator default US location vs Physical Phone in India)
      if (rawDist > 50000) {
        normalizedWorkerLoc = LatLng(
          _customerLatLng.latitude + 0.0015,
          _customerLatLng.longitude + 0.0015,
        );
      } else {
        normalizedWorkerLoc = LatLng(rawLat, rawLng);
      }

      if (_workerLatLng?.latitude != normalizedWorkerLoc.latitude ||
          _workerLatLng?.longitude != normalizedWorkerLoc.longitude) {
        setState(() {
          _workerLatLng = normalizedWorkerLoc;
        });
        _fitMapBounds();
      }
    }
  }

  void _fitMapBounds() {
    if (_workerLatLng == null) return;

    try {
      final bounds = LatLngBounds.fromPoints([_customerLatLng, _workerLatLng!]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(70.0),
        ),
      );
    } catch (e) {
      debugPrint('MapController fitCamera deferral: $e');
    }
  }

  void _zoomIn() {
    try {
      _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
    } catch (e) {
      debugPrint('Zoom in error: $e');
    }
  }

  void _zoomOut() {
    try {
      _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
    } catch (e) {
      debugPrint('Zoom out error: $e');
    }
  }

  String _calculateDistanceAndEta() {
    if (_workerLatLng == null) return 'Calculating...';
    
    try {
      final distanceMeters = const Distance().distance(_customerLatLng, _workerLatLng!);
      if (distanceMeters < 100) {
        return 'Arrived nearby (< 100m)';
      } else if (distanceMeters < 1000) {
        final mins = (distanceMeters / 250).ceil();
        return '${distanceMeters.toStringAsFixed(0)}m away • ~$mins min arrival';
      } else {
        final km = (distanceMeters / 1000).toStringAsFixed(1);
        final mins = (distanceMeters / 300).ceil();
        return '$km km away • ~$mins mins arrival';
      }
    } catch (e) {
      return 'En-route';
    }
  }

  @override
  Widget build(BuildContext context) {
    final etaText = _calculateDistanceAndEta();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Live Tracking - ${widget.booking.service}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textPrimaryColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppConstants.textPrimaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppConstants.primaryColor),
            tooltip: 'Recenter Map',
            onPressed: _fitMapBounds,
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Tile Engine
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _customerLatLng,
              initialZoom: 15.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.example.skillconnect',
              ),
              if (_workerLatLng != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_customerLatLng, _workerLatLng!],
                      strokeWidth: 4.5,
                      color: AppConstants.primaryColor,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Customer Marker (Destination)
                  Marker(
                    point: _customerLatLng,
                    width: 54,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  // Worker Marker (En-route)
                  if (_workerLatLng != null)
                    Marker(
                      point: _workerLatLng!,
                      width: 54,
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppConstants.successColor.withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppConstants.successColor, width: 2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.two_wheeler,
                            color: AppConstants.successColor,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Floating Top Live ETA Banner (Sleek Glassmorphic Pill)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppConstants.successColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.booking.status == 'InProgress'
                              ? 'Service In Progress ⚡'
                              : 'Service Provider En-Route 🛵',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppConstants.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          etaText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side Floating Zoom Controls
          Positioned(
            top: 90,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomInBtn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppConstants.textPrimaryColor,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOutBtn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppConstants.textPrimaryColor,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Bottom Action Sheet & Provider Info Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: AppConstants.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.booking.service,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                const Text(
                                  '4.9 (Verified Provider)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.textSecondaryColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.successColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.booking.status,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Display Completion OTP if available so Customer has it handy
                  if (widget.booking.completionOtp != null && widget.booking.completionOtp!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppConstants.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(color: AppConstants.secondaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Customer Completion OTP:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.textPrimaryColor),
                          ),
                          Text(
                            widget.booking.completionOtp!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons (Show QR & Call Masked)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppConstants.primaryColor, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => CustomerQrDialog(booking: widget.booking),
                            );
                          },
                          icon: const Icon(Icons.qr_code_2, color: AppConstants.primaryColor),
                          label: const Text(
                            'Show QR Code',
                            style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            ),
                          ),
                          onPressed: () async {
                            final authService = Provider.of<AuthService>(context, listen: false);
                            final userPhone = authService.currentUser?.phone ?? '9876543210';

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📞 Connecting via Twilio Masked Call channel...'),
                                backgroundColor: AppConstants.primaryColor,
                                duration: Duration(seconds: 2),
                              ),
                            );

                            await CommsService.initiateCall(
                              context: context,
                              callerPhone: userPhone,
                              receiverPhone: '9876543210',
                              bookingId: widget.booking.id,
                            );
                          },
                          icon: const Icon(Icons.phone_in_talk, color: Colors.white),
                          label: const Text(
                            'Call Masked',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.booking.status == 'Completed') ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                      onPressed: _showRatingDialog,
                      icon: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
                      label: const Text(
                        '⭐ Rate & Review Service Provider',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
