import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogs/models/notification_model.dart';

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
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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

  /// Save notification to Firestore using NotificationModel
  static Future<String?> saveNotificationToFirestore({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? userId,
    bool isGlobal = false,
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Firestore will generate this
        title: title,
        body: body,
        type: type,
        icon: _getIconForType(type),
        data: data ?? {},
        timestamp: DateTime.now(),
        isRead: false,
        userId: isGlobal ? null : userId,
        isGlobal: isGlobal,
        readBy: {},
      );

      final docRef = await _firestore.collection('notifications').add(notification.toMap());
      print('Notification saved: ${isGlobal ? 'Global' : 'User-specific'} with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving notification: $e');
      return null;
    }
  }

  /// Create a global notification (visible to all users)
  static Future<String?> createGlobalNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    return await saveNotificationToFirestore(
      title: title,
      body: body,
      type: type,
      data: data,
      isGlobal: true,
    );
  }

  /// Create a user-specific notification
  static Future<String?> createUserNotification({
    required String title,
    required String body,
    required String type,
    required String userId,
    Map<String, dynamic>? data,
  }) async {
    return await saveNotificationToFirestore(
      title: title,
      body: body,
      type: type,
      data: data,
      userId: userId,
      isGlobal: false,
    );
  }

  /// Get notifications for a specific user (their notifications + global ones)
  /// Returns a stream of NotificationModel objects
  static Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where(Filter.or(
          Filter('userId', isEqualTo: userId),
          Filter('isGlobal', isEqualTo: true),
        ))
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get notifications query for a specific user (alternative to stream)
  static Query getUserNotificationsQuery(String userId) {
    return _firestore
        .collection('notifications')
        .where(Filter.or(
          Filter('userId', isEqualTo: userId),
          Filter('isGlobal', isEqualTo: true),
        ))
        .orderBy('timestamp', descending: true)
        .limit(50);
  }

  /// Mark a specific notification as read for the current user
  static Future<void> markNotificationAsRead(String notificationId, String userId) async {
    try {
      final notificationRef = _firestore.collection('notifications').doc(notificationId);
      final notificationDoc = await notificationRef.get();
      
      if (!notificationDoc.exists) return;
      
      final notificationModel = NotificationModel.fromFirestore(notificationDoc);
      
      if (notificationModel.isGlobal) {
        // For global notifications, track read status per user
        await notificationRef.update({
          'readBy.$userId': true,
        });
      } else {
        // For user-specific notifications, just mark as read
        await notificationRef.update({'isRead': true});
      }
      
      print('Notification marked as read: $notificationId for user: $userId');
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark a notification as read using NotificationModel
  static Future<void> markNotificationModelAsRead(NotificationModel notification, String userId) async {
    await markNotificationAsRead(notification.id, userId);
  }

  /// Mark all notifications as read for the current user
  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Get user's notifications and global notifications
      final notifications = await _firestore
          .collection('notifications')
          .where(Filter.or(
            Filter('userId', isEqualTo: userId),
            Filter('isGlobal', isEqualTo: true),
          ))
          .get();
      
      for (var doc in notifications.docs) {
        final notificationModel = NotificationModel.fromFirestore(doc);
        
        if (notificationModel.isGlobal) {
          // For global notifications, mark as read for this user only if not already read
          if (!notificationModel.isReadByUser(userId)) {
            batch.update(doc.reference, {'readBy.$userId': true});
          }
        } else {
          // For user-specific notifications, mark as read only if not already read
          if (!notificationModel.isRead) {
            batch.update(doc.reference, {'isRead': true});
          }
        }
      }
      
      await batch.commit();
      print('All notifications marked as read for user: $userId');
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Get unread notification count for a user
  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where(Filter.or(
            Filter('userId', isEqualTo: userId),
            Filter('isGlobal', isEqualTo: true),
          ))
          .get();
      
      int unreadCount = 0;
      for (var doc in notifications.docs) {
        final notificationModel = NotificationModel.fromFirestore(doc);
        if (!notificationModel.isReadByUser(userId)) {
          unreadCount++;
        }
      }
      
      return unreadCount;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Get unread notification count stream for a user
  static Stream<int> getUnreadNotificationCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where(Filter.or(
          Filter('userId', isEqualTo: userId),
          Filter('isGlobal', isEqualTo: true),
        ))
        .snapshots()
        .map((snapshot) {
          int unreadCount = 0;
          for (var doc in snapshot.docs) {
            final notificationModel = NotificationModel.fromFirestore(doc);
            if (!notificationModel.isReadByUser(userId)) {
              unreadCount++;
            }
          }
          return unreadCount;
        });
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('Notification deleted: $notificationId');
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Delete a notification using NotificationModel
  static Future<void> deleteNotificationModel(NotificationModel notification) async {
    await deleteNotification(notification.id);
  }

  /// Check if a notification is read by the current user (using NotificationModel)
  static bool isNotificationReadByUser(NotificationModel notification, String userId) {
    return notification.isReadByUser(userId);
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
    final String? targetUserId = message.data['userId'];
    final bool isGlobal = message.data['isGlobal'] == 'true' || targetUserId == null;
    
    await saveNotificationToFirestore(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'general',
      data: message.data,
      userId: isGlobal ? null : targetUserId,
      isGlobal: isGlobal,
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
      payload: '$type|${jsonEncode(message.data)}',
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
    String? userId,
    bool isGlobal = false,
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
      userId: userId,
      isGlobal: isGlobal,
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