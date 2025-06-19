// models/voucher.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String type;
  final String category; // Added category field
  final String imageUrl;
  final DateTime expiryDate;
  final bool isActive;
  final Map<String, dynamic> metadata;

  Voucher({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.type,
    required this.category, // Added category parameter
    required this.imageUrl,
    required this.expiryDate,
    required this.isActive,
    required this.metadata,
  });

  factory Voucher.fromMap(Map<String, dynamic> map) {
    return Voucher(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      pointsCost: map['pointsCost'] ?? 0,
      type: map['type'] ?? '',
      category: map['category'] ?? 'general', // Default category
      imageUrl: map['imageUrl'] ?? '',
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? false,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'type': type,
      'category': category, // Include category in map
      'imageUrl': imageUrl,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isActive': isActive,
      'metadata': metadata,
    };
  }
}

class UserVoucher {
  final String id;
  final String userId;
  final String voucherId;
  final DateTime redeemedAt;
  final DateTime expiryDate;
  final bool isUsed;
  final DateTime? usedAt;
  final Voucher voucher;

  UserVoucher({
    required this.id,
    required this.userId,
    required this.voucherId,
    required this.redeemedAt,
    required this.expiryDate,
    required this.isUsed,
    this.usedAt,
    required this.voucher,
  });

  factory UserVoucher.fromMap(Map<String, dynamic> map) {
    return UserVoucher(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      voucherId: map['voucherId'] ?? '',
      redeemedAt: (map['redeemedAt'] as Timestamp).toDate(),
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
      isUsed: map['isUsed'] ?? false,
      usedAt: map['usedAt'] != null ? (map['usedAt'] as Timestamp).toDate() : null,
      voucher: Voucher.fromMap(map['voucher']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'voucherId': voucherId,
      'redeemedAt': Timestamp.fromDate(redeemedAt),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isUsed': isUsed,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'voucher': voucher.toMap(),
    };
  }
}