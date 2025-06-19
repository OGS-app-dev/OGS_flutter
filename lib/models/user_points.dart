// models/user_points.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPoints {
  final String userId;
  final int totalPoints;
  final int screenTimeMinutes;
  final DateTime lastUpdated;
  final List<PointTransaction> transactions;

  UserPoints({
    required this.userId,
    required this.totalPoints,
    required this.screenTimeMinutes,
    required this.lastUpdated,
    required this.transactions,
  });

  factory UserPoints.fromMap(Map<String, dynamic> map) {
    return UserPoints(
      userId: map['userId'] ?? '',
      totalPoints: map['totalPoints'] ?? 0,
      screenTimeMinutes: map['screenTimeMinutes'] ?? 0,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
      transactions: (map['transactions'] as List<dynamic>?)
          ?.map((t) => PointTransaction.fromMap(t))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'screenTimeMinutes': screenTimeMinutes,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
  }
}

class PointTransaction {
  final String id;
  final int points;
  final String type;
  final String description;
  final DateTime timestamp;

  PointTransaction({
    required this.id,
    required this.points,
    required this.type,
    required this.description,
    required this.timestamp,
  });

  factory PointTransaction.fromMap(Map<String, dynamic> map) {
    return PointTransaction(
      id: map['id'] ?? '',
      points: map['points'] ?? 0,
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'points': points,
      'type': type,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

