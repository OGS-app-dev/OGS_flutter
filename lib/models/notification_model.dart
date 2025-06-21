import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String icon;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final String? userId;
  final bool isGlobal;
  final Map<String, dynamic> readBy; // For tracking global notification read status

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.icon,
    required this.data,
    required this.timestamp,
    required this.isRead,
    this.userId,
    this.isGlobal = false,
    this.readBy = const {},
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      icon: data['icon'] ?? 'notifications',
      data: (data['data'] is Map<String, dynamic>) ? Map<String, dynamic>.from(data['data']) : {},
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      userId: data['userId'],
      isGlobal: data['isGlobal'] ?? false,
      readBy: (data['readBy'] is Map<String, dynamic>) ? Map<String, dynamic>.from(data['readBy']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'body': body,
      'type': type,
      'icon': icon,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isGlobal': isGlobal,
    };

    if (!isGlobal && userId != null) {
      map['userId'] = userId as Object;
    }

    if (isGlobal && readBy.isNotEmpty) {
      map['readBy'] = readBy;
    }

    return map;
  }

  /// Check if this notification is read by a specific user
  bool isReadByUser(String userId) {
    if (isGlobal) {
      return readBy[userId] == true;
    } else {
      return isRead;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min ago';
    } else {
      return 'Just now';
    }
  }

  IconData get iconData {
    switch (icon) {
      case 'directions_bus':
        return Icons.directions_bus;
      case 'event':
        return Icons.event;
      case 'movie':
        return Icons.movie;
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_offer':
        return Icons.local_offer;
      case 'stars':
        return Icons.stars;
      default:
        return Icons.notifications;
    }
  }

  /// Get display indicator for notification type
  String get typeIndicator {
    if (isGlobal) {
      return '🌐 '; // Global indicator
    }
    return '';
  }
}