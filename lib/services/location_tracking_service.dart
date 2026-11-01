import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'socket_service.dart';

class LocationTrackingService {
  StreamSubscription<Position>? _positionStreamSub;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  // Start streaming worker location en-route to customer
  Future<void> startWorkerTracking({
    required String bookingId,
    required String customerId,
    required SocketService socketService,
  }) async {
    if (_isTracking) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _isTracking = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters moved
    );

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        debugPrint('[WORKER GPS STREAM] Lat: ${position.latitude}, Lng: ${position.longitude}');
        socketService.emitWorkerLocation(
          bookingId: bookingId,
          customerId: customerId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      },
      onError: (e) {
        debugPrint('Location stream error: $e');
      },
    );
  }

  // Stop location tracking
  void stopTracking() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _isTracking = false;
  }
}
