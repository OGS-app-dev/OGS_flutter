
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
  await OGSNotificationService._showLocalNotification(message);
  await OGSNotificationService._saveNotificationFromRemoteMessage(message);
}

class OGSNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Function(String, Map<String, dynamic>)? onNotificationTap;

  static final Set<String> _knownChannels = {
    'bus',
    'event',
    'offer',
    'movie',
    'general',
  };

  static Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static Future<void> _createNotificationChannels() async {
    final List<AndroidNotificationChannel> channels = [
      const AndroidNotificationChannel(
        'bus_channel',
        'Bus Notifications',
        description: 'Notifications for bus tracking and updates',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'events_channel',
        'Event Notifications',
        description: 'Notifications for events and activities',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'offers_channel',
        'Offers & Deals',
        description: 'Notifications for special offers and deals',
        importance: Importance.max,
      ),
      const AndroidNotificationChannel(
        'movies_channel',
        'Movie Notifications',
        description: 'Notifications for movie bookings and updates',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'general_channel',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.high,
      ),
    ];

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      for (final channel in channels) {
        await androidImplementation.createNotificationChannel(channel);
      }
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> saveNotificationToFirestore({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? userId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'icon': _getIconForType(type),
      });
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  static String _getIconForType(String type) {
    switch (type) {
      case 'bus':
        return 'directions_bus';
      case 'event':
        return 'event';
      case 'movie':
        return 'movie';
      case 'hotel':
        return 'hotel';
      case 'restaurant':
        return 'restaurant';
      case 'offer':
        return 'local_offer';
      case 'points':
        return 'stars';
      default:
        return 'notifications';
    }
  }

  // Foreground message handler
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.messageId}');
    await _showLocalNotification(message);
    await _saveNotificationFromRemoteMessage(message);
  }

  // App opened via notification
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message opened app: ${message.messageId}');
    _handleNotificationNavigation(message.data);
  }

  // Save Firebase notification to Firestore
  static Future<void> _saveNotificationFromRemoteMessage(RemoteMessage message) async {
    await saveNotificationToFirestore(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'general',
      data: message.data,
      userId: message.data['userId'],
    );
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final String type = message.data['type'] ?? 'general';
    final String channelId =
        _knownChannels.contains(type) ? '${type}_channel' : 'general_channel';

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFFDA45),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message',
      platformChannelSpecifics,
      payload:
          '$type|${jsonEncode(message.data)}', // safer payload encoding
    );
  }

  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'bus_channel':
        return 'Bus Notifications';
      case 'events_channel':
        return 'Event Notifications';
      case 'offers_channel':
        return 'Offers & Deals';
      case 'movies_channel':
        return 'Movie Notifications';
      default:
        return 'General Notifications';
    }
  }

  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'bus_channel':
        return 'Notifications for bus tracking and updates';
      case 'events_channel':
        return 'Notifications for events and activities';
      case 'offers_channel':
        return 'Notifications for special offers and deals';
      case 'movies_channel':
        return 'Notifications for movie bookings and updates';
      default:
        return 'General app notifications';
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final parts = response.payload!.split('|');
      if (parts.length >= 2) {
        final type = parts[0];
        final dataString = parts[1];
        try {
          final Map<String, dynamic> data =
              jsonDecode(dataString) as Map<String, dynamic>;

          _handleNotificationNavigation({'type': type, ...data});
        } catch (e) {
          print('Error decoding notification payload: $e');
        }
      }
    }
  }

  // Handle navigation logic
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final String type = data['type'] ?? 'general';
    if (onNotificationTap != null) {
      onNotificationTap!(type, data);
    }
  }

  // Manually send local notification
  static Future<void> sendLocalNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final String channelId =
        _knownChannels.contains(type) ? '${type}_channel' : 'general_channel';

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFFDA45),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: '$type|${jsonEncode(data ?? {})}',
    );

    // Save to Firestore
    await saveNotificationToFirestore(
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  static Future<void> sendTokenToServer(String userId) async {
    String? token = await getToken();
    if (token != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('FCM Token updated for user: $userId');
      } catch (e) {
        print('Error updating FCM token: $e');
      }
    }
  }
}
