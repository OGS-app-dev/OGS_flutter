import 'package:flutter/material.dart';
import 'package:ogs/constants.dart';
import 'dart:math' as math; 
import 'package:ogs/pages/comingsoon.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:ogs/pages/s_help_support.dart';
import 'package:ogs/pages/s_privacy_policy.dart';
import 'package:ogs/pages/notificationpage.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
    final  TextEditingController _searchController = TextEditingController();

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
          gradient:const LinearGradient(
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
                      'Settings',
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
          const SizedBox(height: 20,),
          // Search field with proper padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search now',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Menu items with proper padding from left
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0),
            child: Column(
              children: [
                _buildMenuItem(
                  Icons.person, 
                  'Account',
                  onTap: () => _navigateToPage(const ComingSoon()),
                ),
                _buildMenuItem(
                  Icons.notifications, 
                  'Notifications',
                  onTap: () => _navigateToPage( NotificationPage()), 
                ),
                _buildMenuItem(
                  Icons.lock, 
                  'Privacy and Security',
                  onTap: () => _navigateToPage(const PrivacyPolicyScreen()),
                ),
                _buildMenuItem(
                  Icons.headset_mic, 
                  'Help and Support',
                  onTap: () => _navigateToPage(const HelpSupportScreen()), 
                ),
                _buildMenuItem(
                  Icons.info_outline, 
                  'About',
                  onTap: () => _navigateToPage(const ComingSoon()),
                ),
                _buildMenuItem(
                  Icons.person_add, 
                  'Invite your Friends',
                  onTap: () => _navigateToPage(const ComingSoon()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 240, 240, 240), 
                borderRadius: BorderRadius.circular(8.0), 
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(icon, color: const Color.fromARGB(255, 0, 0, 0), size: 24),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text, 
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    var paintBlue = Paint()..color =pricol;
    var pathBlue = Path();

    pathBlue.moveTo(0, size.height * 0.7); 
    pathBlue.quadraticBezierTo(size.width / 2, size.height * 0.85, size.width, size.height * 0);
    pathBlue.lineTo(size.width, size.height);
    pathBlue.lineTo(0, size.height);
    pathBlue.close();
    canvas.drawPath(pathBlue, paintBlue);

    var paintYellow = Paint()..color =const Color(0xFFFFDA45);
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