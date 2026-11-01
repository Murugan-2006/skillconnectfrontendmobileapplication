import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class SocketService extends ChangeNotifier {
  IO.Socket? _socket;
  bool _isConnected = false;
  
  // List of active job offers for the worker
  final List<Map<String, dynamic>> _bookingOffers = [];
  
  // Latest booking response received for the customer
  Map<String, dynamic>? _acceptedBooking;

  // Latest live location update received for a worker en-route
  Map<String, dynamic>? _latestWorkerLocation;

  // Latest booking completed for customer feedback
  Map<String, dynamic>? _completedBooking;

  IO.Socket? get socket => _socket;
  bool get isConnected => _isConnected;
  List<Map<String, dynamic>> get bookingOffers => _bookingOffers;
  Map<String, dynamic>? get acceptedBooking => _acceptedBooking;
  Map<String, dynamic>? get completedBooking => _completedBooking;
  Map<String, dynamic>? get latestWorkerLocation => _latestWorkerLocation;

  // Initialize socket connection
  void initSocket(String userId, String role, String? skill) {
    // Extract base URL from ApiConfig.baseUrl (remove '/api')
    String serverUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    
    // Disconnect existing if any
    disconnectSocket();

    debugPrint('Initializing WebSocket connection to $serverUrl');
    
    _socket = IO.io(serverUrl, IO.OptionBuilder()
      .setTransports(['websocket']) // Use websocket transport
      .disableAutoConnect() // Don't connect immediately
      .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('WebSocket Connected successfully: ${_socket!.id}');
      _isConnected = true;
      notifyListeners();

      // Register the user with the backend
      _socket!.emit('register', {
        'userId': userId,
        'role': role,
        'skill': skill,
      });
    });

    _socket!.onDisconnect((_) {
      debugPrint('WebSocket Disconnected');
      _isConnected = false;
      notifyListeners();
    });

    // Listen for new booking offers (Workers only)
    _socket!.on('new_booking_offer', (data) {
      debugPrint('Received new booking offer: $data');
      final offer = Map<String, dynamic>.from(data);
      
      // Prevent duplicates
      _bookingOffers.removeWhere((o) => o['bookingId'] == offer['bookingId']);
      _bookingOffers.add(offer);
      notifyListeners();
    });

    // Listen for bookings claimed by others (Workers only)
    _socket!.on('booking_taken', (data) {
      debugPrint('Booking taken by another worker: $data');
      final bookingId = data['bookingId'].toString();
      _bookingOffers.removeWhere((offer) => offer['bookingId'] == bookingId);
      notifyListeners();
    });

    // Listen for booking accepted (Customers only)
    _socket!.on('booking_accepted', (data) {
      debugPrint('Customer booking accepted: $data');
      _acceptedBooking = Map<String, dynamic>.from(data['booking']);
      notifyListeners();
    });

    // Listen for general status updates (Customers only)
    _socket!.on('booking_status_updated', (data) {
      debugPrint('Customer booking status updated: $data');
      _acceptedBooking = Map<String, dynamic>.from(data['booking']);
      notifyListeners();
    });

    // Listen for live worker location updates (Customers only)
    _socket!.on('worker_location_updated', (data) {
      debugPrint('Received live worker location update: $data');
      _latestWorkerLocation = Map<String, dynamic>.from(data);
      notifyListeners();
    });

    // Listen for booking completed (Customers only)
    _socket!.on('booking_completed', (data) {
      debugPrint('Customer booking completed event received: $data');
      if (data['booking'] != null) {
        _completedBooking = Map<String, dynamic>.from(data['booking']);
        notifyListeners();
      }
    });
  }

  void emitWorkerLocation({
    required String bookingId,
    required String customerId,
    required double latitude,
    required double longitude,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('update_worker_location', {
        'bookingId': bookingId,
        'customerId': customerId,
        'latitude': latitude,
        'longitude': longitude,
      });
    }
  }

  void clearAcceptedBooking() {
    _acceptedBooking = null;
    notifyListeners();
  }

  void clearCompletedBooking() {
    _completedBooking = null;
    notifyListeners();
  }

  void removeOffer(String bookingId) {
    _bookingOffers.removeWhere((offer) => offer['bookingId'] == bookingId);
    notifyListeners();
  }

  void disconnectSocket() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _bookingOffers.clear();
    _acceptedBooking = null;
    _latestWorkerLocation = null;
  }
}
