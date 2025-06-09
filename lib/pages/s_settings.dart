import 'package:flutter/material.dart';
import 'package:ogs/constants.dart';
import 'dart:math' as math; 
import 'package:ogs/pages/comingsoon.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:ogs/pages/s_help_support.dart';
import 'package:ogs/pages/s_privacy_policy.dart';
import 'package:ogs/pages/notificationpage.dart';
import 'package:ogs/pages/s_about_us.dart';


class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Define all menu items
  final List<MenuItem> _allMenuItems = [
    MenuItem(
      icon: Icons.person,
      title: 'Account',
      keywords: ['account', 'profile', 'user', 'personal'],
    ),
    MenuItem(
      icon: Icons.notifications,
      title: 'Notifications',
      keywords: ['notifications', 'alerts', 'sounds', 'push'],
    ),
    MenuItem(
      icon: Icons.lock,
      title: 'Privacy and Security',
      keywords: ['privacy', 'security', 'password', 'lock', 'protection'],
    ),
    MenuItem(
      icon: Icons.headset_mic,
      title: 'Help and Support',
      keywords: ['help', 'support', 'contact', 'assistance', 'faq'],
    ),
    MenuItem(
      icon: Icons.info_outline,
      title: 'About',
      keywords: ['about', 'info', 'version', 'app info'],
    ),
    // MenuItem(
    //   icon: Icons.person_add,
    //   title: 'Invite your Friends',
    //   keywords: ['invite', 'friends', 'share', 'referral'],
    // ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<MenuItem> get _filteredMenuItems {
    if (_searchQuery.isEmpty) {
      return _allMenuItems;
    }
    
    return _allMenuItems.where((item) {
      // Search in title
      if (item.title.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      
      // Search in keywords
      return item.keywords.any((keyword) => 
        keyword.toLowerCase().contains(_searchQuery)
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredMenuItems;
    
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
                hintText: 'Search Now...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35.0),
              child: filteredItems.isEmpty
                  ? _buildNoResultsWidget()
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildMenuItem(
                          item.icon,
                          item.title,
                          onTap: () => _navigateToPage(_getPageForMenuItem(item.title)),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No settings found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.transparent,
          ),
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
              // Icon(
              //   Icons.arrow_forward_ios,
              //   size: 16,
              //   color: Colors.grey.shade400,
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPageForMenuItem(String title) {
    switch (title) {
      case 'Notifications':
        return NotificationPage();
      case 'Privacy and Security':
        return const PrivacyPolicyScreen();
      case 'Help and Support':
        return const HelpSupportScreen();
      case 'About':
        return const AboutUsScreen();
      default:
        return const ComingSoon();
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

class MenuItem {
  final IconData icon;
  final String title;
  final List<String> keywords;

  MenuItem({
    required this.icon,
    required this.title,
    required this.keywords,
  });
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