// models/voucher.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String id;
  final String title;
  final String description;
  final String category; // 'signup', 'milestone', 'general'
  final int pointsCost;
  final String redeemCode; // Code that users enter to redeem
  final String imageUrl;
  final DateTime expiryDate;
  final bool isActive;
  final String? brandName;
  final String? termsAndConditions;
  final int? maxRedemptions; // Optional: limit total redemptions
  final int currentRedemptions; // Track how many times redeemed
  final Map<String, dynamic> metadata; // Additional data

  Voucher({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.pointsCost,
    required this.redeemCode,
    required this.imageUrl,
    required this.expiryDate,
    required this.isActive,
    this.brandName,
    this.termsAndConditions,
    this.maxRedemptions,
    this.currentRedemptions = 0,
    this.metadata = const {},
  });

  factory Voucher.fromMap(Map<String, dynamic> map) {
    return Voucher(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'general',
      pointsCost: map['pointsCost'] ?? 0,
      redeemCode: map['redeemCode'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      brandName: map['brandName'],
      termsAndConditions: map['termsAndConditions'],
      maxRedemptions: map['maxRedemptions'],
      currentRedemptions: map['currentRedemptions'] ?? 0,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'pointsCost': pointsCost,
      'redeemCode': redeemCode,
      'imageUrl': imageUrl,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isActive': isActive,
      'brandName': brandName,
      'termsAndConditions': termsAndConditions,
      'maxRedemptions': maxRedemptions,
      'currentRedemptions': currentRedemptions,
      'metadata': metadata,
    };
  }

  // Helper methods
  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isAvailableForRedemption => isActive && !isExpired && (maxRedemptions == null || currentRedemptions < maxRedemptions!);
  
  String get formattedExpiryDate {
    return "${expiryDate.day}/${expiryDate.month}/${expiryDate.year}";
  }
}

class UserVoucher {
  final String id;
  final String userId;
  final String voucherId;
  final DateTime unlockedAt;
  final DateTime? redeemedAt;
  final DateTime expiryDate;
  final bool isUsed;
  final bool isUnlocked;
  final int pointsSpent;
  final String unlockReason; // 'signup_bonus', 'milestone_100', 'points_unlock'
  final String? redeemCode; // Code entered when redeeming
  final Voucher voucher;

  UserVoucher({
    required this.id,
    required this.userId,
    required this.voucherId,
    required this.unlockedAt,
    this.redeemedAt,
    required this.expiryDate,
    required this.isUsed,
    required this.isUnlocked,
    required this.pointsSpent,
    required this.unlockReason,
    this.redeemCode,
    required this.voucher,
  });

  factory UserVoucher.fromMap(Map<String, dynamic> map) {
    return UserVoucher(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      voucherId: map['voucherId'] ?? '',
      unlockedAt: (map['unlockedAt'] as Timestamp).toDate(),
      redeemedAt: map['redeemedAt'] != null ? (map['redeemedAt'] as Timestamp).toDate() : null,
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
      isUsed: map['isUsed'] ?? false,
      isUnlocked: map['isUnlocked'] ?? true,
      pointsSpent: map['pointsSpent'] ?? 0,
      unlockReason: map['unlockReason'] ?? '',
      redeemCode: map['redeemCode'],
      voucher: Voucher.fromMap(map['voucher'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'voucherId': voucherId,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
      'redeemedAt': redeemedAt != null ? Timestamp.fromDate(redeemedAt!) : null,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isUsed': isUsed,
      'isUnlocked': isUnlocked,
      'pointsSpent': pointsSpent,
      'unlockReason': unlockReason,
      'redeemCode': redeemCode,
      'voucher': voucher.toMap(),
    };
  }

  // Helper methods
  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get canBeRedeemed => isUnlocked && !isUsed && !isExpired;
  
  String get status {
    if (isUsed) return 'Used';
    if (isExpired) return 'Expired';
    if (isUnlocked) return 'Ready to Use';
    return 'Available';
  }
  
  String get statusDescription {
    if (isUsed && redeemedAt != null) {
      return 'Used on ${_formatDate(redeemedAt!)}';
    }
    if (isExpired) {
      return 'Expired on ${_formatDate(expiryDate)}';
    }
    if (isUnlocked) {
      return 'Expires on ${_formatDate(expiryDate)}';
    }
    return 'Available to unlock';
  }
  
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
  
  // Time remaining until expiry
  Duration get timeUntilExpiry => expiryDate.difference(DateTime.now());
  
  String get timeUntilExpiryText {
    if (isExpired) return 'Expired';
    
    final duration = timeUntilExpiry;
    if (duration.inDays > 0) {
      return '${duration.inDays} days left';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours left';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minutes left';
    } else {
      return 'Expires soon';
    }
  }
}