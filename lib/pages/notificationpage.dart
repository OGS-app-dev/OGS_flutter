import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogs/constants.dart';
import 'dart:math' as math; 
import 'dart:async';
import 'package:ogs/pages/comingsoon.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:ogs/pages/s_help_support.dart';
import 'package:ogs/pages/s_privacy_policy.dart';
import 'package:ogs/models/notification_model.dart';
import 'package:ogs/services/notifications_service.dart';
import 'package:ogs/pages/fnu_hotel.dart';
import 'package:ogs/pages/fnu_movies.dart';
import 'package:ogs/pages/events_view_all.dart';
import 'package:ogs/pages/ads_view_all.dart';
import 'package:ogs/pages/fnu_restaurants.dart';
import 'package:ogs/pages/bus.dart';
import 'package:ogs/pages/s_vouchers.dart';
import 'package:ogs/pages/s_points_page.dart';

class NotificationPage extends StatefulWidget {
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = _auth.currentUser?.uid;
    
    if (currentUserId == null) {
      return Scaffold(
        body: Center(
          child: Text('Please log in to view notifications'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          Stack(
            children: [
              CustomPaint(
                painter: CurvePainter(),
                child: Container(height: 180),
              ),
              Positioned(
                top: 70,
                left: 20,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.yellow, Colors.white], 
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0), size: 20), 
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () => _markAllAsRead(currentUserId),
                  child: Text(
                    'Mark all as read',
                    style: TextStyle(
                      color: pricol,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _getCombinedNotificationsStream(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(pricol),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final notifications = snapshot.data!
                    .where((notification) {
                      if (_searchQuery.isEmpty) return true;
                      return notification.title.toLowerCase().contains(_searchQuery) ||
                             notification.body.toLowerCase().contains(_searchQuery);
                    })
                    .toList();

                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(notification, currentUserId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<NotificationModel>> _getCombinedNotificationsStream(String currentUserId) {
    final StreamController<List<NotificationModel>> controller = StreamController<List<NotificationModel>>.broadcast();
    
    QuerySnapshot? userSnapshot;
    QuerySnapshot? globalSnapshot;
    bool userLoaded = false;
    bool globalLoaded = false;
    
    // Stream for user-specific notifications
    final userNotificationsStream = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('isGlobal', isEqualTo: false) // Explicitly exclude global ones
        .orderBy('timestamp', descending: true)
        .limit(25)
        .snapshots();

    // Stream for global notifications
    final globalNotificationsStream = _firestore
        .collection('notifications')
        .where('isGlobal', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(25)
        .snapshots();

    void combineAndEmit() {
      if (userLoaded && globalLoaded) {
        List<NotificationModel> allNotifications = [];

        // Add user-specific notifications
        if (userSnapshot != null) {
          allNotifications.addAll(
            userSnapshot!.docs.map((doc) => NotificationModel.fromFirestore(doc))
          );
        }

        // Add global notifications
        if (globalSnapshot != null) {
          allNotifications.addAll(
            globalSnapshot!.docs.map((doc) => NotificationModel.fromFirestore(doc))
          );
        }

        // Sort all notifications by timestamp (most recent first)
        allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Limit to 50 total notifications
        if (allNotifications.length > 50) {
          allNotifications = allNotifications.take(50).toList();
        }

        if (!controller.isClosed) {
          controller.add(allNotifications);
        }
      }
    }

    // Listen to user notifications
    final userSubscription = userNotificationsStream.listen(
      (snapshot) {
        userSnapshot = snapshot;
        userLoaded = true;
        combineAndEmit();
      },
      onError: (error) {
        print('Error in user notifications stream: $error');
        userLoaded = true;
        combineAndEmit();
      },
    );

    // Listen to global notifications
    final globalSubscription = globalNotificationsStream.listen(
      (snapshot) {
        globalSnapshot = snapshot;
        globalLoaded = true;
        combineAndEmit();
      },
      onError: (error) {
        print('Error in global notifications stream: $error');
        globalLoaded = true;
        combineAndEmit();
      },
    );

    controller.onCancel = () {
      userSubscription.cancel();
      globalSubscription.cancel();
    };

    return controller.stream;
  }

  Widget _buildNotificationCard(NotificationModel notification, String currentUserId) {
    // Check read status correctly for both global and user-specific notifications
    final bool isNotificationRead = notification.isReadByUser(currentUserId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNotificationRead ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNotificationRead ? Colors.grey[200]! : Colors.blue[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColorForType(notification.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification.iconData,
                color: _getColorForType(notification.type),
                size: 24,
              ),
            ),
            // Add a small global indicator for global notifications
            // if (notification.isGlobal)
            //   Positioned(
            //     right: 0,
            //     top: 0,
            //     child: Container(
            //       width: 12,
            //       height: 12,
            //       decoration: BoxDecoration(
            //         color: Colors.orange,
            //         shape: BoxShape.circle,
            //         border: Border.all(color: Colors.white, width: 1),
            //       ),
            //       child: Icon(
            //         Icons.public,
            //         size: 8,
            //         color: Colors.white,
            //       ),
            //     ),
            //   ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: isNotificationRead ? FontWeight.w500 : FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            // Add a "Global" badge for global notifications
            // if (notification.isGlobal)
            //   Container(
            //     padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            //     decoration: BoxDecoration(
            //       color: Colors.orange.withOpacity(0.1),
            //       borderRadius: BorderRadius.circular(8),
            //       border: Border.all(color: Colors.orange.withOpacity(0.3)),
            //     ),
            //     child: Text(
            //       'Global',
            //       style: TextStyle(
            //         fontSize: 10,
            //         color: Colors.orange[700],
            //         fontWeight: FontWeight.w600,
            //       ),
            //     ),
            //   ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notification.timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: !isNotificationRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: pricol,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          _handleNotificationTap(notification, currentUserId);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something important happens',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'bus':
        return Colors.blue;
      case 'event':
        return Colors.purple;
      case 'movie':
        return Colors.red;
      case 'hotel':
        return Colors.green;
      case 'restaurant':
        return Colors.orange;
      case 'offer':
        return Colors.amber;
      case 'points':
        return Colors.teal;
      case 'vouchers':
        return const Color.fromARGB(255, 31, 135, 204);
      default:
        return pricol;
    }
  }

  void _handleNotificationTap(NotificationModel notification, String currentUserId) {
    // Mark notification as read properly for both global and user-specific
    _markAsRead(notification, currentUserId);
    
    _navigateBasedOnType(notification.type, notification.data);
  }

  void _navigateBasedOnType(String type, Map<String, dynamic> data) {
    Widget? page;
    
    switch (type) {
      case 'bus':
        page = const BusTrackPage(); 
        break;
      case 'event':
        page = const EventsViewAll();
        break;
      case 'movie':
        page = const MoviesPage(); 
        break;
      case 'hotel':
        page = const HotelPage(); 
        break;
      case 'restaurant':
        page = const RestaurantsPage(); 
        break;
      case 'offer':
        page = const AdsViewAll(); 
        break;
        case 'points':
        page =  PointsScreen(); 
        break;
        case 'vouchers':
        page = const VouchersScreen(); 
        break;
      default:
        return;
    }
    
    if (page != null) {
      _navigateToPage(page);
    }
  }

  Future<void> _markAsRead(NotificationModel notification, String currentUserId) async {
    try {
      if (notification.isGlobal) {
        // For global notifications, mark as read for this user
        await _firestore
            .collection('notifications')
            .doc(notification.id)
            .update({'readBy.$currentUserId': true});
      } else {
        // For user-specific notifications, mark as read
        await _firestore
            .collection('notifications')
            .doc(notification.id)
            .update({'isRead': true});
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead(String currentUserId) async {
    try {
      final batch = _firestore.batch();
      
      // Get user-specific notifications
      final userNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isGlobal', isEqualTo: false)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in userNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      // Get global notifications that haven't been read by this user
      final globalNotifications = await _firestore
          .collection('notifications')
          .where('isGlobal', isEqualTo: true)
          .get();
      
      for (var doc in globalNotifications.docs) {
        final data = doc.data();
        final readBy = Map<String, dynamic>.from(data['readBy'] ?? {});
        
        // Only update if this user hasn't read it yet
        if (readBy[currentUserId] != true) {
          batch.update(doc.reference, {'readBy.$currentUserId': true});
        }
      }
      
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: pricol,
        ),
      );
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  void _navigateToPage(Widget page) {
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: page,
      withNavBar: true,
      pageTransitionAnimation: PageTransitionAnimation.cupertino,
    );
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paintBlue = Paint()..color = pricol;
    var pathBlue = Path();

    pathBlue.moveTo(0, size.height * 0.7); 
    pathBlue.quadraticBezierTo(size.width / 2, size.height * 0.85, size.width, size.height * 0);
    pathBlue.lineTo(size.width, size.height);
    pathBlue.lineTo(0, size.height);
    pathBlue.close();
    canvas.drawPath(pathBlue, paintBlue);

    var paintYellow = Paint()..color = const Color(0xFFFFDA45);
    var pathYellow = Path();

    pathYellow.moveTo(0, 0.2);
    pathYellow.lineTo(size.width * 1.1, 0);
    pathYellow.quadraticBezierTo(size.width * 0.9, size.height * 0.9, 0.1, size.height * 0.9);
    pathYellow.close();
    canvas.drawPath(pathYellow, paintYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}