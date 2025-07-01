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
import 'package:ogs/pages/s_profile_edit.dart';

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
    // Determine auth provider
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

    // Get name from various sources
    String name = firebaseUser.displayName ?? '';
    if (name.isEmpty && firebaseUser.email != null) {
      name = firebaseUser.email!.split('@')[0];
    }
    if (name.isEmpty) {
      name = 'User';
    }

    // Get profile image URL
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

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  AppUser? _appUser;
  bool _isLoading = true;
  String? _errorMessage;

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

      // Try to get user data from Firestore first
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        // User exists in Firestore
        _appUser = AppUser.fromFirestore(userDoc);

        // Update Firestore with latest Firebase Auth data if needed
        await _syncFirebaseAuthWithFirestore();
      } else {
        // User doesn't exist in Firestore, create from Firebase Auth data
        _appUser = AppUser.fromFirebaseUser(_currentUser!);

        // Save new user to Firestore
        await _createUserInFirestore();
      }
    } catch (e) {
      _errorMessage = "Error loading profile: ${e.toString()}";
      print("Error in _fetchUserData: $e");

      // Fallback: create user from Firebase Auth if possible
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
      // Check if we need to update any fields from Firebase Auth
      bool needsUpdate = false;
      Map<String, dynamic> updates = {};

      // Update name if it's different or empty in Firestore
      String authName = _currentUser!.displayName ?? '';
      if (authName.isEmpty && _currentUser!.email != null) {
        authName = _currentUser!.email!.split('@')[0];
      }
      if (authName.isNotEmpty && _appUser!.name != authName) {
        updates['name'] = authName;
        needsUpdate = true;
      }

      // Update email if different
      if (_currentUser!.email != null &&
          _appUser!.email != _currentUser!.email!) {
        updates['email'] = _currentUser!.email!;
        needsUpdate = true;
      }

      // Update profile image if different (and not empty)
      if (_currentUser!.photoURL != null &&
          _currentUser!.photoURL!.isNotEmpty &&
          _appUser!.profileImageUrl != _currentUser!.photoURL!) {
        updates['profileImageUrl'] = _currentUser!.photoURL!;
        needsUpdate = true;
      }

      // Update email verification status
      if (_appUser!.isEmailVerified != _currentUser!.emailVerified) {
        updates['isEmailVerified'] = _currentUser!.emailVerified;
        needsUpdate = true;
      }

      // Update auth provider info
      String currentAuthProvider = 'email';
      if (_currentUser!.providerData.isNotEmpty) {
        final providerId = _currentUser!.providerData.first.providerId;
        switch (providerId) {
          case 'google.com':
            currentAuthProvider = 'google';
            break;
          case 'facebook.com':
            currentAuthProvider = 'facebook';
            break;
          case 'apple.com':
            currentAuthProvider = 'apple';
            break;
          default:
            currentAuthProvider = 'email';
        }
      }

      if (_appUser!.authProvider != currentAuthProvider) {
        updates['authProvider'] = currentAuthProvider;
        needsUpdate = true;
      }

      if (needsUpdate) {
        updates['lastUpdated'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update(updates);

        // Refresh user data after update
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

  Future<void> _refreshUserData() async {
    await _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final String userName = _appUser?.name ?? 'Loading User...';
    final String userEmail = _appUser?.email ?? 'Loading Email...';
    final String profileUrl = _appUser?.profileImageUrl ??
        'lib/assets/images/placeholder_profile.png';

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _appUser == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshUserData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Curved yellow background
                    Container(
                      height: 182,
                      color: yel,
                    ),

                    // Content
                    SafeArea(
                      child: Column(
                        children: [
                          // Profile title
                          Padding(
                            padding: const EdgeInsets.fromLTRB(29, 60, 20, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Profile',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 1),

                          // Profile picture positioned to overlap with curve
                          Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 8,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 58,
                                  backgroundImage: profileUrl.startsWith('http')
                                      ? NetworkImage(profileUrl)
                                          as ImageProvider
                                      : AssetImage(profileUrl) as ImageProvider,
                                  onBackgroundImageError:
                                      (exception, stackTrace) {
                                    print(
                                        'Error loading profile image: $exception');
                                  },
                                  child: profileUrl.isEmpty
                                      ? Container(
                                          width: 116,
                                          height: 116,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey,
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 58,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 7,
                                right: 5,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFDA45),
                                    shape: BoxShape.circle,
                                    border: Border.symmetric(
                                      horizontal: BorderSide(
                                          color: Colors.white, width: 2),
                                      vertical: BorderSide(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _navigateToPage(
                                        const EditProfilePage()),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // User name and email
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),

                          const SizedBox(height: 12),
                          const Divider(
                            color: Color.fromARGB(255, 222, 222, 222),
                            thickness: 0.5,
                            height: 8,
                          ),
                          const SizedBox(height: 24),

                          // Features Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildFeatureItem(
                                  Icons.monetization_on_outlined,
                                  'Points',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => PointsScreen()),
                                  ),
                                ),
                              const  SizedBox(
                                  height: 35, 
                                  child:  VerticalDivider(
                                    color: Color.fromARGB(255, 222, 222, 222),
                                    thickness: 0.5,
                                    width: 5,
                                  ),
                                ),
                                _buildFeatureItem(
                                  Icons.card_giftcard_outlined,
                                  'Voucher',
                                  onTap: () =>
                                      _navigateToPage(const VouchersScreen()),
                                ),
                                 const  SizedBox(
                                  height: 35, 
                                  child:  VerticalDivider(
                                    color: Color.fromARGB(255, 222, 222, 222),
                                    thickness: 0.5,
                                    width: 5,
                                  ),
                                ),
                                _buildFeatureItem(
                                  Icons.star_border,
                                  'Rating',
                                  onTap: () =>
                                      _navigateToPage(const RatingScreen()),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Divider(
                            color: Color.fromARGB(255, 222, 222, 222),
                            thickness: 0.8,
                            height: 8,
                          ),
                          const SizedBox(height: 12),

                          // Menu Items
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  children: [
                                    _buildMenuItem(
                                      Icons.settings,
                                      'Settings',
                                      onTap: () =>
                                          _navigateToPage(SettingsScreen()),
                                    ),
                                    _buildMenuItem(
                                      Icons.feedback,
                                      'Send Feedback',
                                      onTap: () =>
                                          _navigateToPage(const FeedbackScreen()),
                                    ),
                                    _buildMenuItem(
                                      Icons.info,
                                      'About us',
                                      onTap: () =>
                                          _navigateToPage(const AboutUsScreen()),
                                    ),
                                    _buildMenuItem(
                                      Icons.logout,
                                      'Log out',
                                      onTap: () => _handleLogout(),
                                    ),
                                    const SizedBox(height: 100,)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text,
      {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: 25,
          ),
        ),
        title: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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
