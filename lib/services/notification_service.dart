import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'accepted', 'in_progress', 'completed', 'general'
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic>? bookingData;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.bookingData,
  });
}

class NotificationService extends ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? bookingData,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      bookingData: bookingData,
    );

    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
