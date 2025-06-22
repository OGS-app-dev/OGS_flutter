import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ogs/models/user_points.dart';
import 'package:ogs/services/notifications_service.dart';
import 'package:ogs/models/voucher.dart';

class PointsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String POINTS_COLLECTION = 'user_points';
  static const String VOUCHERS_COLLECTION = 'vouchers';
  static const String USER_VOUCHERS_COLLECTION = 'user_vouchers';
  
  // Initialize user points on first signup
  static Future<void> initializeUserPoints(String userId) async {
    try {
      final userPointsRef = _firestore.collection(POINTS_COLLECTION).doc(userId);
      final doc = await userPointsRef.get();
      
      if (!doc.exists) {
        final initialPoints = UserPoints(
          userId: userId,
          totalPoints: 10, // Sign-up bonus
          screenTimeMinutes: 0,
          lastUpdated: DateTime.now(),
          transactions: [
            PointTransaction(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              points: 10,
              type: 'signup_bonus',
              description: 'Welcome bonus for signing up!',
              timestamp: DateTime.now(),
            ),
          ],
        );
        
        await userPointsRef.set(initialPoints.toMap());
        
        // Grant first-time sign-in voucher
        await _grantSignupVoucher(userId);
        
        // Show welcome notification
        await OGSNotificationService.saveNotificationToFirestore(
          title: '🎉 Welcome Bonus!',
          body: 'You earned 10 points for signing up!',
          type: 'points',
          data: {'points': 10, 'reason': 'signup_bonus'},
          userId: userId,
        );
        
        // Also send local notification
        await OGSNotificationService.sendLocalNotification(
          title: '🎉 Welcome Bonus!',
          body: 'You earned 10 points for signing up!',
          type: 'points',
          data: {'points': 10, 'reason': 'signup_bonus'},
        );
      }
    } catch (e) {
      print('Error initializing user points: $e');
    }
  }
  
  // Add points for various activities
  static Future<void> addPoints({
    required String userId,
    required int points,
    required String type,
    required String description,
  }) async {
    try {
      final userPointsRef = _firestore.collection(POINTS_COLLECTION).doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userPointsRef);
        
        if (doc.exists) {
          final currentData = UserPoints.fromMap(doc.data()!);
          final newTransaction = PointTransaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            points: points,
            type: type,
            description: description,
            timestamp: DateTime.now(),
          );
          
          final oldPoints = currentData.totalPoints;
          final newPoints = oldPoints + points;
          
          final updatedPoints = UserPoints(
            userId: userId,
            totalPoints: newPoints,
            screenTimeMinutes: currentData.screenTimeMinutes,
            lastUpdated: DateTime.now(),
            transactions: [newTransaction, ...currentData.transactions],
          );
          
          transaction.set(userPointsRef, updatedPoints.toMap());
          
          // Check if user reached milestone after this addition
          await _checkAndGrantMilestoneVoucher(userId, oldPoints, newPoints);
        }
      });
      
      // Show points notification
      await _showPointsNotification(userId, points, description);
      
    } catch (e) {
      print('Error adding points: $e');
    }
  }
  
  // Track screen time and award points (5 points every 5 minutes)
  static Future<void> trackScreenTime(String userId, int minutes) async {
    try {
      final userPointsRef = _firestore.collection(POINTS_COLLECTION).doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userPointsRef);
        
        if (doc.exists) {
          final currentData = UserPoints.fromMap(doc.data()!);
          final newScreenTime = currentData.screenTimeMinutes + minutes;
          
          // Award 5 points every 5 minutes
          final pointsToAward = ((newScreenTime ~/ 5) - (currentData.screenTimeMinutes ~/ 5)) * 5;
          
          if (pointsToAward > 0) {
            final newTransaction = PointTransaction(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              points: pointsToAward,
              type: 'screen_time',
              description: 'Earned from ${(pointsToAward ~/ 5) * 5} minutes of app usage',
              timestamp: DateTime.now(),
            );
            
            final oldPoints = currentData.totalPoints;
            final newPoints = oldPoints + pointsToAward;
            
            final updatedPoints = UserPoints(
              userId: userId,
              totalPoints: newPoints,
              screenTimeMinutes: newScreenTime,
              lastUpdated: DateTime.now(),
              transactions: [newTransaction, ...currentData.transactions],
            );
            
            transaction.set(userPointsRef, updatedPoints.toMap());
            
            // Check if user reached milestone after screen time points
            await _checkAndGrantMilestoneVoucher(userId, oldPoints, newPoints);
            
            // Show notification for screen time points
            await _showPointsNotification(
              userId,
              pointsToAward,
              'Great job! You earned points for using the app',
            );
          } else {
            // Just update screen time without adding points
            final updatedPoints = UserPoints(
              userId: currentData.userId,
              totalPoints: currentData.totalPoints,
              screenTimeMinutes: newScreenTime,
              lastUpdated: DateTime.now(),
              transactions: currentData.transactions,
            );
            
            transaction.set(userPointsRef, updatedPoints.toMap());
          }
        }
      });
      
    } catch (e) {
      print('Error tracking screen time: $e');
    }
  }
  
  // Grant voucher for first-time signup
  static Future<void> _grantSignupVoucher(String userId) async {
    try {
      // Get available vouchers for signup category
      final availableVouchers = await _getAvailableVouchersByCategory('signup');
      
      if (availableVouchers.isNotEmpty) {
        // Grant the first available signup voucher
        final voucher = availableVouchers.first;
        await _unlockVoucherForUser(userId, voucher, 'signup_bonus', 0);
        
        // Show voucher notification
        await OGSNotificationService.saveNotificationToFirestore(
          title: '🎁 Welcome Voucher!',
          body: 'You received a special voucher: ${voucher.title}',
          type: 'voucher',
          data: {
            'voucherId': voucher.id,
            'reason': 'signup_bonus',
          },
          userId: userId,
        );
        
        // Also send local notification
        await OGSNotificationService.sendLocalNotification(
          title: '🎁 Welcome Voucher!',
          body: 'You received a special voucher: ${voucher.title}',
          type: 'voucher',
          data: {
            'voucherId': voucher.id,
            'reason': 'signup_bonus',
          },
        );
      }
    } catch (e) {
      print('Error granting signup voucher: $e');
    }
  }
  
  // Check and grant milestone voucher when user reaches 100 points
  static Future<void> _checkAndGrantMilestoneVoucher(String userId, int oldPoints, int newPoints) async {
    try {
      // Calculate how many times user crossed 100-point milestones
      final oldMilestones = oldPoints ~/ 100;
      final newMilestones = newPoints ~/ 100;
      
      if (newMilestones > oldMilestones) {
        final vouchersToGrant = newMilestones - oldMilestones;
        
        // Get available vouchers for milestone category
        final availableVouchers = await _getAvailableVouchersByCategory('milestone');
        
        if (availableVouchers.isNotEmpty) {
          for (int i = 0; i < vouchersToGrant && i < availableVouchers.length; i++) {
            final voucher = availableVouchers[i % availableVouchers.length];
            await _unlockVoucherForUser(userId, voucher, 'milestone_100', 0);
            
            // Show voucher notification
            await OGSNotificationService.saveNotificationToFirestore(
              title: '🏆 Milestone Voucher!',
              body: 'Congratulations! You earned a voucher for reaching ${(oldMilestones + i + 1) * 100} points: ${voucher.title}',
              type: 'voucher',
              data: {
                'voucherId': voucher.id,
                'reason': 'milestone_100',
                'milestone': (oldMilestones + i + 1) * 100,
              },
              userId: userId,
            );
            
            // Also send local notification
            await OGSNotificationService.sendLocalNotification(
              title: '🏆 Milestone Voucher!',
              body: 'Congratulations! You earned a voucher for reaching ${(oldMilestones + i + 1) * 100} points: ${voucher.title}',
              type: 'voucher',
              data: {
                'voucherId': voucher.id,
                'reason': 'milestone_100',
                'milestone': (oldMilestones + i + 1) * 100,
              },
            );
          }
        }
      }
    } catch (e) {
      print('Error checking milestone voucher: $e');
    }
  }
  
  // Get available vouchers by category
  static Future<List<Voucher>> _getAvailableVouchersByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('vouchers')
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: category)
          .where('expiryDate', isGreaterThan: Timestamp.now())
          .get();
      
      return querySnapshot.docs
          .map((doc) => Voucher.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting vouchers by category: $e');
      return [];
    }
  }
  
  // Unlock voucher for user (doesn't deduct points, just makes it available)
  static Future<void> _unlockVoucherForUser(String userId, Voucher voucher, String reason, int pointsSpent) async {
    try {
      final userVoucher = UserVoucher(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        voucherId: voucher.id,
        unlockedAt: DateTime.now(),
        expiryDate: DateTime.now().add(Duration(days: 30)), // 30 days validity
        isUsed: false,
        isUnlocked: true,
        pointsSpent: pointsSpent,
        unlockReason: reason,
        voucher: voucher,
      );
      
      final userVoucherRef = _firestore.collection(USER_VOUCHERS_COLLECTION).doc();
      await userVoucherRef.set(userVoucher.toMap());
      
    } catch (e) {
      print('Error unlocking voucher for user: $e');
    }
  }
  
  // Unlock voucher with points (user clicks unlock/redeem button)
  static Future<VoucherUnlockResult> unlockVoucherWithPoints(String userId, String voucherId) async {
    try {
      // Check if user already has this voucher
      final existingVoucher = await _checkIfUserHasVoucher(userId, voucherId);
      if (existingVoucher != null) {
        return VoucherUnlockResult(
          success: false,
          message: 'You already have this voucher!',
          errorCode: 'ALREADY_OWNED'
        );
      }
      
      final userPointsRef = _firestore.collection(POINTS_COLLECTION).doc(userId);
      final voucherRef = _firestore.collection(VOUCHERS_COLLECTION).doc(voucherId);
      
      return await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userPointsRef);
        final voucherDoc = await transaction.get(voucherRef);
        
        if (!userDoc.exists || !voucherDoc.exists) {
          return VoucherUnlockResult(
            success: false,
            message: 'User or voucher not found',
            errorCode: 'NOT_FOUND'
          );
        }
        
        final userPoints = UserPoints.fromMap(userDoc.data()!);
        final voucher = Voucher.fromMap({...voucherDoc.data()!, 'id': voucherDoc.id});
        
        // Check if voucher is active and not expired
        if (!voucher.isActive || voucher.expiryDate.isBefore(DateTime.now())) {
          return VoucherUnlockResult(
            success: false,
            message: 'This voucher is no longer available',
            errorCode: 'EXPIRED'
          );
        }
        
        if (userPoints.totalPoints < voucher.pointsCost) {
          return VoucherUnlockResult(
            success: false,
            message: 'Not enough points! You need ${voucher.pointsCost} points.',
            errorCode: 'INSUFFICIENT_POINTS'
          );
        }
        
        // Deduct points
        final newTransaction = PointTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          points: -voucher.pointsCost,
          type: 'voucher_unlocked',
          description: 'Unlocked: ${voucher.title}',
          timestamp: DateTime.now(),
        );
        
        final updatedPoints = UserPoints(
          userId: userId,
          totalPoints: userPoints.totalPoints - voucher.pointsCost,
          screenTimeMinutes: userPoints.screenTimeMinutes,
          lastUpdated: DateTime.now(),
          transactions: [newTransaction, ...userPoints.transactions],
        );
        
        transaction.set(userPointsRef, updatedPoints.toMap());
        
        // Add voucher to user's collection
        final userVoucher = UserVoucher(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          voucherId: voucherId,
          unlockedAt: DateTime.now(),
          expiryDate: DateTime.now().add(Duration(days: 30)), // 30 days validity
          isUsed: false,
          isUnlocked: true,
          pointsSpent: voucher.pointsCost,
          unlockReason: 'points_unlock',
          voucher: voucher,
        );
        
        final userVoucherRef = _firestore.collection(USER_VOUCHERS_COLLECTION).doc();
        transaction.set(userVoucherRef, userVoucher.toMap());
        
        return VoucherUnlockResult(
          success: true,
          message: 'Voucher unlocked successfully!',
          userVoucher: userVoucher
        );
      });
    } catch (e) {
      print('Error unlocking voucher: $e');
      return VoucherUnlockResult(
        success: false,
        message: 'Error unlocking voucher: $e',
        errorCode: 'ERROR'
      );
    }
  }
  
  // Check if user already has a specific voucher
  static Future<UserVoucher?> _checkIfUserHasVoucher(String userId, String voucherId) async {
    try {
      final querySnapshot = await _firestore
          .collection(USER_VOUCHERS_COLLECTION)
          .where('userId', isEqualTo: userId)
          .where('voucherId', isEqualTo: voucherId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return UserVoucher.fromMap({...querySnapshot.docs.first.data(), 'id': querySnapshot.docs.first.id});
      }
      return null;
    } catch (e) {
      print('Error checking user voucher: $e');
      return null;
    }
  }
  
  // Use/Redeem voucher with code
  static Future<VoucherRedeemResult> redeemVoucherWithCode(String userId, String userVoucherId, String code) async {
    try {
      final userVoucherRef = _firestore.collection(USER_VOUCHERS_COLLECTION).doc(userVoucherId);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userVoucherRef);
        
        if (!doc.exists) {
          return VoucherRedeemResult(
            success: false,
            message: 'Voucher not found',
            errorCode: 'NOT_FOUND'
          );
        }
        
        final userVoucher = UserVoucher.fromMap({...doc.data()!, 'id': doc.id});
        
        // Check if this voucher belongs to the user
        if (userVoucher.userId != userId) {
          return VoucherRedeemResult(
            success: false,
            message: 'This voucher doesn\'t belong to you',
            errorCode: 'UNAUTHORIZED'
          );
        }
        
        // Check if voucher is already used
        if (userVoucher.isUsed) {
          return VoucherRedeemResult(
            success: false,
            message: 'This voucher has already been used',
            errorCode: 'ALREADY_USED'
          );
        }
        
        // Check if voucher is expired
        if (userVoucher.expiryDate.isBefore(DateTime.now())) {
          return VoucherRedeemResult(
            success: false,
            message: 'This voucher has expired',
            errorCode: 'EXPIRED'
          );
        }
        
        // Verify the redemption code
        if (userVoucher.voucher.redeemCode != code) {
          return VoucherRedeemResult(
            success: false,
            message: 'Invalid redemption code',
            errorCode: 'INVALID_CODE'
          );
        }
        
        // Mark voucher as used
        final updatedUserVoucher = UserVoucher(
          id: userVoucher.id,
          userId: userVoucher.userId,
          voucherId: userVoucher.voucherId,
          unlockedAt: userVoucher.unlockedAt,
          redeemedAt: DateTime.now(),
          expiryDate: userVoucher.expiryDate,
          isUsed: true,
          isUnlocked: userVoucher.isUnlocked,
          pointsSpent: userVoucher.pointsSpent,
          unlockReason: userVoucher.unlockReason,
          redeemCode: code,
          voucher: userVoucher.voucher,
        );
        
        transaction.set(userVoucherRef, updatedUserVoucher.toMap());
        
        return VoucherRedeemResult(
          success: true,
          message: 'Voucher redeemed successfully!',
          userVoucher: updatedUserVoucher
        );
      });
    } catch (e) {
      print('Error redeeming voucher: $e');
      return VoucherRedeemResult(
        success: false,
        message: 'Error redeeming voucher: $e',
        errorCode: 'ERROR'
      );
    }
  }
  
  // Get user points
  static Future<UserPoints?> getUserPoints(String userId) async {
    try {
      final doc = await _firestore.collection(POINTS_COLLECTION).doc(userId).get();
      if (doc.exists) {
        return UserPoints.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Error getting user points: $e');
    }
    return null;
  }
  
  // Get available vouchers with user's unlock status
  static Future<List<VoucherWithStatus>> getAvailableVouchersWithStatus(String userId) async {
    try {
      // Get all available vouchers
      final vouchersSnapshot = await _firestore
          .collection('vouchers')
          //.where('isActive', isEqualTo: true)
         // .where('expiryDate', isGreaterThan: Timestamp.now())
          .orderBy('expiryDate')
          .get();
      
      // Get user's vouchers
      final userVouchersSnapshot = await _firestore
          .collection(USER_VOUCHERS_COLLECTION)
          .where('userId', isEqualTo: userId)
          .get();
      
      final userVoucherIds = userVouchersSnapshot.docs
          .map((doc) => UserVoucher.fromMap({...doc.data(), 'id': doc.id}))
          .map((uv) => uv.voucherId)
          .toSet();
      
      final userVouchersMap = Map.fromEntries(
        userVouchersSnapshot.docs
            .map((doc) => UserVoucher.fromMap({...doc.data(), 'id': doc.id}))
            .map((uv) => MapEntry(uv.voucherId, uv))
      );
      
      return vouchersSnapshot.docs.map((doc) {
        final voucher = Voucher.fromMap({...doc.data(), 'id': doc.id});
        final isUnlocked = userVoucherIds.contains(voucher.id);
        final userVoucher = userVouchersMap[voucher.id];
        
        return VoucherWithStatus(
          voucher: voucher,
          isUnlocked: isUnlocked,
          isUsed: userVoucher?.isUsed ?? false,
          userVoucher: userVoucher,
        );
      }).toList();
    } catch (e) {
      print('Error getting vouchers with status: $e');
      return [];
    }
  }
  
  // Get user's vouchers (unlocked/redeemed)
  static Future<List<UserVoucher>> getUserVouchers(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(USER_VOUCHERS_COLLECTION)
          .where('userId', isEqualTo: userId)
          .orderBy('unlockedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserVoucher.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting user vouchers: $e');
      return [];
    }
  }
  
  // Show points notification with animation
  static Future<void> _showPointsNotification(String userId, int points, String description) async {
    String emoji = points >= 10 ? '🎉' : '⭐';
    String title = points >= 10 ? 'Awesome! +$points Points!' : '+$points Points!';
    
    // Save to Firestore with userId
    await OGSNotificationService.saveNotificationToFirestore(
      title: '$emoji $title',
      body: description,
      type: 'points',
      data: {
        'points': points,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      },
      userId: userId,
    );
    
    // Also send local notification
    await OGSNotificationService.sendLocalNotification(
      title: '$emoji $title',
      body: description,
      type: 'points',
      data: {
        'points': points,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  // Activities that award points
  static Future<void> awardFacilityViewPoints(String userId) async {
    await addPoints(
      userId: userId,
      points: 1,
      type: 'facility_view',
      description: 'Viewed facility details',
    );
  }
  
  static Future<void> awardSearchPoints(String userId) async {
    await addPoints(
      userId: userId,
      points: 2,
      type: 'search',
      description: 'Used search functionality',
    );
  }
  
  static Future<void> awardDailyLoginPoints(String userId) async {
    // Check if already awarded today
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getString('last_login_points_${userId}');
    final today = DateTime.now().toDateString();
    
    if (lastLogin != today) {
      await addPoints(
        userId: userId,
        points: 5,
        type: 'daily_login',
        description: 'Daily login bonus',
      );
      await prefs.setString('last_login_points_${userId}', today);
    }
  }
}

// Result classes for voucher operations
class VoucherUnlockResult {
  final bool success;
  final String message;
  final String? errorCode;
  final UserVoucher? userVoucher;
  
  VoucherUnlockResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.userVoucher,
  });
}

class VoucherRedeemResult {
  final bool success;
  final String message;
  final String? errorCode;
  final UserVoucher? userVoucher;
  
  VoucherRedeemResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.userVoucher,
  });
}

// Voucher with status for UI
class VoucherWithStatus {
  final Voucher voucher;
  final bool isUnlocked;
  final bool isUsed;
  final UserVoucher? userVoucher;

  VoucherWithStatus({
    required this.voucher,
    required this.isUnlocked,
    required this.isUsed,
    this.userVoucher,
  });

  bool get canUnlock => !isUnlocked && !isUsed;
  bool get canRedeem => isUnlocked && !isUsed;

  String get status {
    if (isUsed) return 'Used';
    if (isUnlocked) return 'Unlocked';
    return 'Available';
  }

  // ✅ Add this inside the class
  VoucherWithStatus copyWith({
    bool? isUnlocked,
    bool? isUsed,
    UserVoucher? userVoucher,
  }) {
    return VoucherWithStatus(
      voucher: this.voucher,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isUsed: isUsed ?? this.isUsed,
      userVoucher: userVoucher ?? this.userVoucher,
    );
  }
}


// Extension for date formatting
extension DateExtension on DateTime {
  String toDateString() {
    return '${this.year}-${this.month.toString().padLeft(2, '0')}-${this.day.toString().padLeft(2, '0')}';
  }
}