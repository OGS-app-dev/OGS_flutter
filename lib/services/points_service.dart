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
        
        // Show welcome notification
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
          
          final updatedPoints = UserPoints(
            userId: userId,
            totalPoints: currentData.totalPoints + points,
            screenTimeMinutes: currentData.screenTimeMinutes,
            lastUpdated: DateTime.now(),
            transactions: [newTransaction, ...currentData.transactions],
          );
          
          transaction.set(userPointsRef, updatedPoints.toMap());
        }
      });
      
      // Show points notification
      await _showPointsNotification(points, description);
      
    } catch (e) {
      print('Error adding points: $e');
    }
  }
  
  // Track screen time and award points
  static Future<void> trackScreenTime(String userId, int minutes) async {
    try {
      final userPointsRef = _firestore.collection(POINTS_COLLECTION).doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userPointsRef);
        
        if (doc.exists) {
          final currentData = UserPoints.fromMap(doc.data()!);
          final newScreenTime = currentData.screenTimeMinutes + minutes;
          
          // Award points every 5 minutes
          final pointsToAward = (newScreenTime ~/ 5) - (currentData.screenTimeMinutes ~/ 5);
          
          if (pointsToAward > 0) {
            final newTransaction = PointTransaction(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              points: pointsToAward * 2, // 2 points per 5-minute interval
              type: 'screen_time',
              description: 'Earned from ${pointsToAward * 5} minutes of app usage',
              timestamp: DateTime.now(),
            );
            
            final updatedPoints = UserPoints(
              userId: userId,
              totalPoints: currentData.totalPoints + (pointsToAward * 2),
              screenTimeMinutes: newScreenTime,
              lastUpdated: DateTime.now(),
              transactions: [newTransaction, ...currentData.transactions],
            );
            
            transaction.set(userPointsRef, updatedPoints.toMap());
            
            // Show notification for screen time points
            await _showPointsNotification(
              pointsToAward * 2,
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
  
  // Get available vouchers
  static Future<List<Voucher>> getAvailableVouchers() async {
    try {
      final querySnapshot = await _firestore
          .collection(VOUCHERS_COLLECTION)
          .where('isActive', isEqualTo: true)
          .where('expiryDate', isGreaterThan: Timestamp.now())
          .orderBy('expiryDate')
          .get();
      
      return querySnapshot.docs
          .map((doc) => Voucher.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting vouchers: $e');
      return [];
    }
  }
  
  // Redeem voucher
  static Future<bool> redeemVoucher(String userId, String voucherId) async {
    try {
      final userPointsRef = _firestore.collection(POINTS_COLLECTION).doc(userId);
      final voucherRef = _firestore.collection(VOUCHERS_COLLECTION).doc(voucherId);
      
      return await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userPointsRef);
        final voucherDoc = await transaction.get(voucherRef);
        
        if (!userDoc.exists || !voucherDoc.exists) {
          return false;
        }
        
        final userPoints = UserPoints.fromMap(userDoc.data()!);
        final voucher = Voucher.fromMap({...voucherDoc.data()!, 'id': voucherDoc.id});
        
        if (userPoints.totalPoints < voucher.pointsCost) {
          return false; // Not enough points
        }
        
        // Deduct points
        final newTransaction = PointTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          points: -voucher.pointsCost,
          type: 'voucher_redeemed',
          description: 'Redeemed: ${voucher.title}',
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
          redeemedAt: DateTime.now(),
          expiryDate: DateTime.now().add(Duration(days: 30)), // 30 days validity
          isUsed: false,
          voucher: voucher,
        );
        
        final userVoucherRef = _firestore.collection(USER_VOUCHERS_COLLECTION).doc();
        transaction.set(userVoucherRef, userVoucher.toMap());
        
        return true;
      });
    } catch (e) {
      print('Error redeeming voucher: $e');
      return false;
    }
  }
  
  // Get user's vouchers
  static Future<List<UserVoucher>> getUserVouchers(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(USER_VOUCHERS_COLLECTION)
          .where('userId', isEqualTo: userId)
          .orderBy('redeemedAt', descending: true)
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
  static Future<void> _showPointsNotification(int points, String description) async {
    String emoji = points >= 10 ? '🎉' : '⭐';
    String title = points >= 10 ? 'Awesome! +$points Points!' : '+$points Points!';
    
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

// Extension for date formatting
extension DateExtension on DateTime {
  String toDateString() {
    return '${this.year}-${this.month.toString().padLeft(2, '0')}-${this.day.toString().padLeft(2, '0')}';
  }
}

