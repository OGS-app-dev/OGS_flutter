import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogs/constants.dart';
import 'dart:math' as math; 
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


class NotificationPage extends StatefulWidget {
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
          
          // Notification Actions
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
                  onPressed: _markAllAsRead,
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
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(pricol),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final notifications = snapshot.data!.docs
                    .map((doc) => NotificationModel.fromFirestore(doc))
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
                    return _buildNotificationCard(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey[200]! : Colors.blue[200]!,
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
        leading: Container(
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
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
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
        trailing: !notification.isRead
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
          _handleNotificationTap(notification);
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
      default:
        return pricol;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    _markAsRead(notification.id);
    
    _navigateBasedOnType(notification.type, notification.data);
  }

  void _navigateBasedOnType(String type, Map<String, dynamic> data) {
    Widget? page;
    
    switch (type) {
        case 'bus':
          page =const BusTrackPage(); 
          break;
        case 'event':
          page =const  EventsViewAll();
          break;
        case 'movie':
          page =const  MoviesPage(); 
          break;
        case 'hotel':
          page =const  HotelPage(); 
          break;
        case 'restaurant':
          page = const RestaurantsPage(); 
          break;
        case 'offer':
          page =const  AdsViewAll(); 
          break;
        default:
          return;
      }
    
    if (page != null) {
      _navigateToPage(page);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
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