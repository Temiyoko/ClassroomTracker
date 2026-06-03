import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/app_notification.dart';
import 'persistence_service.dart';

class NotificationService with ChangeNotifier {
  List<AppNotification> _notifications = [];
  static const String _storageKey = 'app_notifications';
  
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationService() {
    _loadNotifications();
    _initLocalNotifications();
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click if needed
      },
    );

    // Request permission for Android 13+
    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (platform != null) {
      await platform.requestNotificationsPermission();
    }
  }

  Future<void> _showSystemNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'classroom_alerts',
      'Alertes Salles',
      channelDescription: 'Notifications quand une salle favorite devient libre',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().hashCode,
      title,
      body,
      details,
    );
  }

  Future<void> _loadNotifications() async {
    final data = await PersistenceService.getList(_storageKey);
    if (data.isNotEmpty) {
      _notifications = data
          .map((item) => AppNotification.fromJson(jsonDecode(item)))
          .toList();
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    }
  }

  Future<void> _saveNotifications() async {
    final data = _notifications
        .map((n) => jsonEncode(n.toJson()))
        .toList();
    await PersistenceService.saveList(_storageKey, data);
  }

  Future<void> addNotification(String title, String body) async {
    final notif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, notif);
    await _saveNotifications();
    
    // Also show the real system push notification
    await _showSystemNotification(title, body);

    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }
}
