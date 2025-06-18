import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:ogs/pages/comingsoon.dart';
import 'package:ogs/pages/s_points_page.dart';
import 'package:intl/intl.dart';
import 'student_or_staff_login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ogs/pages/s_settings.dart';
import 'package:ogs/pages/s_feedback.dart';
import 'package:ogs/pages/s_about_us.dart';
import 'package:ogs/pages/s_vouchers.dart';
import 'package:ogs/pages/s_rating.dart';
import 'package:ogs/pages/profile_page_new_2.dart';
import 'package:ogs/pages/map_page.dart';
import 'package:ogs/pages/bus.dart';
import 'package:ogs/pages/homepage.dart';
import 'package:ogs/pages/notificationpage.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String profileImageUrl;
  final DateTime memberSince;
  final String studentStatus;
  final String authProvider;
  final bool isEmailVerified;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.memberSince,
    required this.studentStatus,
    required this.authProvider,
    required this.isEmailVerified,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? 'User Name',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'] ??
          'lib/assets/images/placeholder_profile.png',
      memberSince:
          (data['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
      studentStatus: data['studentStatus'] ?? '',
      authProvider: data['authProvider'] ?? 'email',
      isEmailVerified: data['isEmailVerified'] ?? false,
    );
  }

  factory AppUser.fromFirebaseUser(User firebaseUser,
      {String? firestoreStudentStatus}) {
    String authProvider = 'email';
    if (firebaseUser.providerData.isNotEmpty) {
      final providerId = firebaseUser.providerData.first.providerId;
      switch (providerId) {
        case 'google.com':
          authProvider = 'google';
          break;
        case 'facebook.com':
          authProvider = 'facebook';
          break;
        case 'apple.com':
          authProvider = 'apple';
          break;
        case 'twitter.com':
          authProvider = 'twitter';
          break;
        case 'github.com':
          authProvider = 'github';
          break;
        default:
          authProvider = 'email';
      }
    }

    String name = firebaseUser.displayName ?? '';
    if (name.isEmpty && firebaseUser.email != null) {
      name = firebaseUser.email!.split('@')[0];
    }
    if (name.isEmpty) {
      name = 'User';
    }

    String profileImageUrl =
        firebaseUser.photoURL ?? 'lib/assets/images/placeholder_profile.png';

    return AppUser(
      uid: firebaseUser.uid,
      name: name,
      email: firebaseUser.email ?? '',
      profileImageUrl: profileImageUrl,
      memberSince: firebaseUser.metadata.creationTime ?? DateTime.now(),
      studentStatus: firestoreStudentStatus ?? '',
      authProvider: authProvider,
      isEmailVerified: firebaseUser.emailVerified,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'memberSince': Timestamp.fromDate(memberSince),
      'studentStatus': studentStatus,
      'authProvider': authProvider,
      'isEmailVerified': isEmailVerified,
      'lastUpdated': Timestamp.now(),
    };
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? _currentUser;
  AppUser? _appUser;
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedMenuItem; // Track selected menu item - now null by default
  String? _hoveredMenuItem; // Track hovered menu item - now properly initialized as null

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentUser = FirebaseAuth.instance.currentUser;

      if (_currentUser == null) {
        throw Exception("No user is currently logged in");
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        _appUser = AppUser.fromFirestore(userDoc);
        await _syncFirebaseAuthWithFirestore();
      } else {
        _appUser = AppUser.fromFirebaseUser(_currentUser!);
        await _createUserInFirestore();
      }
    } catch (e) {
      _errorMessage = "Error loading profile: ${e.toString()}";
      print("Error in _fetchUserData: $e");

      if (_currentUser != null) {
        _appUser = AppUser.fromFirebaseUser(_currentUser!);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncFirebaseAuthWithFirestore() async {
    if (_currentUser == null || _appUser == null) return;

    try {
      bool needsUpdate = false;
      Map<String, dynamic> updates = {};

      String authName = _currentUser!.displayName ?? '';
      if (authName.isEmpty && _currentUser!.email != null) {
        authName = _currentUser!.email!.split('@')[0];
      }
      if (authName.isNotEmpty && _appUser!.name != authName) {
        updates['name'] = authName;
        needsUpdate = true;
      }

      if (needsUpdate) {
        updates['lastUpdated'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update(updates);

        DocumentSnapshot updatedDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        _appUser = AppUser.fromFirestore(updatedDoc);
      }
    } catch (e) {
      print("Error syncing Firebase Auth with Firestore: $e");
    }
  }

  Future<void> _createUserInFirestore() async {
    if (_currentUser == null || _appUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set(_appUser!.toFirestore());

      print("Created new user profile in Firestore for ${_appUser!.email}");
    } catch (e) {
      print("Error creating user in Firestore: $e");
    }
  }

  void _updateSelectedMenuItem(String? menuItem) {
    setState(() {
      _selectedMenuItem = menuItem;
    });
  }

  void _updateHoveredMenuItem(String? menuItem) {
    setState(() {
      _hoveredMenuItem = menuItem;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _appUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchUserData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 255, 207, 16),
                  Color.fromARGB(255, 255, 255, 255),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 1.0],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20,),
                Container(
                  width: double.infinity,
                  height: 120,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, top: 25),
                    child: Row(
                      children: [
                  
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundImage:
                                _appUser!.profileImageUrl.startsWith('http')
                                    ? NetworkImage(_appUser!.profileImageUrl)
                                        as ImageProvider
                                    : AssetImage(_appUser!.profileImageUrl)
                                        as ImageProvider,
                            onBackgroundImageError: (exception, stackTrace) {
                              print('Error loading profile image: $exception');
                            },
                            child: _appUser!.profileImageUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _appUser!.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _appUser!.email,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      _buildMenuItem(
                        icon: Icons.home_outlined,
                        title: 'Home',
                        onTap: () {
                          _navigateToPage(const HomePage());
                        },
                        isSelected: false, // No default selection
                        isHovered: _hoveredMenuItem == 'Home',
                      ),
                      _buildMenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'Campus tracking',
                        onTap: () {
                          _navigateToPage(const CollegeMapScreen());
                        },
                        isSelected: false, // No default selection
                        isHovered: _hoveredMenuItem == 'Campus tracking',
                      ),
                      _buildMenuItem(
                        icon: Icons.directions_bus_outlined,
                        title: 'Bus tracking',
                        onTap: () {
                          _navigateToPage(const BusTrackPage());
                        },
                        isSelected: false, // No default selection
                        isHovered: _hoveredMenuItem == 'Bus tracking',
                      ),
                      _buildMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        onTap: () {
                          _navigateToPage(NotificationPage());
                        },
                        isSelected: false, // No default selection
                        isHovered: _hoveredMenuItem == 'Notifications',
                      ),
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'Profile',
                        onTap: () {
                          _navigateToPage(const ProfileScreen());
                        },
                        isSelected: false, // No default selection
                        isHovered: _hoveredMenuItem == 'Profile',
                      ),
                      const SizedBox(height: 140),
                      const Divider(
                        color: Color.fromARGB(255, 210, 210, 210),
                        thickness: 0.8,
                        height: 8,
                      ),
                      _buildMenuItem(
                        icon: Icons.settings_rounded,
                        title: 'Settings',
                        onTap: () {
                          _navigateToPage(SettingsScreen());
                        },
                        isSelected: false, // No default selection
                        isHovered: _hoveredMenuItem == 'Settings',
                      ),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Log out',
                        onTap: _handleLogout,
                        isSelected: false, // Logout should never be selected
                        isHovered: _hoveredMenuItem == 'Log out',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isHovered = false,
  }) {
    bool showHighlight = isSelected || isHovered;

    return MouseRegion(
      onEnter: (_) => _updateHoveredMenuItem(title),
      onExit: (_) => _updateHoveredMenuItem(null),
      child: GestureDetector(
        onTapDown: (_) => _updateHoveredMenuItem(title),  // Touch down (mobile)
        onTapUp: (_) => _updateHoveredMenuItem(null),     // Touch up - reset to null
        onTapCancel: () => _updateHoveredMenuItem(null),  // Touch cancelled - reset to null
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: showHighlight
                ? const Color.fromARGB(255, 0, 0, 0)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: showHighlight
                ? Border.all(color: Colors.black, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: showHighlight
                ? const Color.fromARGB(255, 255, 255, 255)
                : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: showHighlight
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),
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

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                try {
                  await GoogleSignIn().signOut();
                } catch (e) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(e.toString()),
                      ),
                    );
                  }
                }
                if (context.mounted) {
                  Provider.of<FormResponse>(context, listen: false)
                      .tabController!
                      .jumpToTab(0);

                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const StudentOrStaff();
                      },
                    ),
                    (_) => false,
                  );
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}