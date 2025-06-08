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
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      icon: data['icon'] ?? 'notifications',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'icon': icon,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'userId': userId,
    };
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
}