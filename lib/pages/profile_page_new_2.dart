import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:ogs/pages/comingsoon.dart';
// Import your other pages here
// import 'package:ogs/pages/about_us.dart';
// import 'package:ogs/pages/settings.dart';
// import 'package:ogs/pages/feedback.dart';
// import 'package:ogs/pages/report.dart';
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

  factory AppUser.fromFirebaseUser(User firebaseUser, {String? firestoreStudentStatus}) {
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
    String profileImageUrl = firebaseUser.photoURL ?? 'lib/assets/images/placeholder_profile.png';

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
      if (_currentUser!.email != null && _appUser!.email != _currentUser!.email!) {
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
    final String profileUrl = _appUser?.profileImageUrl ??
        'lib/assets/images/placeholder_profile.png';
    final String memberSinceText = _appUser != null
        ? 'Since ${DateFormat('d MMMM y').format(_appUser!.memberSince)}'
        : 'Since N/A';
    final String studentStatus = _appUser?.studentStatus ?? '';
    final String authProvider = _appUser?.authProvider ?? 'email';
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: 
      _isLoading
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
          Container(
            color:const  Color.fromARGB(0, 3, 3, 1),
            child: Column(
              children: [
                CustomPaint(
                  painter: CurvePainter(),
                  child: Container(
                    color:const  Color.fromARGB(0, 3, 3, 1),
                    height: 200, 
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 80, 
            left: 0,
            right: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            
             const Padding(
                padding:  EdgeInsets.only(left: 20),
                child:   Text(
                    'Profile',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color:  Color.fromARGB(255, 0, 0, 0)),
                  ),
              ),
              const  SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient:const LinearGradient(
                      colors: [Color(0xFFFFE57D), Color(0xFFFFDA45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset:const Offset(0, 3), 
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color.fromARGB(255, 255, 255, 255), 
                            width: 5.0,
                          ),
                        ),
                        child: CircleAvatar(
                  radius: 40,
                  backgroundImage: profileUrl.startsWith('http')
                      ? NetworkImage(profileUrl) as ImageProvider
                      : AssetImage(profileUrl) as ImageProvider,
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error loading profile image: $exception');
                  },
                  child: profileUrl.isEmpty
                      ? Container(
                          width: 80,
                          height: 80,
                          decoration:  const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                      ),
                     const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            memberSinceText,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    const  Spacer(),
                    const  Text(
                        'Edit',
                        style:  TextStyle(
                            color:  Color.fromARGB(255, 0, 0, 0),
                            fontSize: 16),
                      ),
                     const Icon(Icons.edit,
                          color:  Color.fromARGB(255, 0, 0, 0), size: 16),
                    ],
                  ),
                ),
               const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeatureItem(Icons.money_rounded, 'Points', onTap:()=> Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>  PointsScreen()),
            )),
                    _buildFeatureItem(Icons.card_giftcard, 'Voucher',onTap: () => _navigateToPage(const ComingSoon())),
                    _buildFeatureItem(Icons.star, 'Rating',onTap: () => _navigateToPage(const ComingSoon())),
                  ],
                ),
              const  SizedBox(height: 30),
              Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0),
            child: Column(
              children: [
                _buildMenuItem(
                  Icons.info_outline, 
                  'About us',
                  onTap: () => _navigateToPage(const ComingSoon()),
                ),
                _buildMenuItem(
                  Icons.settings, 
                  'Settings',
                  onTap: () => _navigateToPage( SettingsScreen()), 
                ),
                _buildMenuItem(
                  Icons.feedback, 
                  'Send Feedback',
                  onTap: () => _navigateToPage(const FeedbackScreen()),
                ),
                _buildMenuItem(
                  Icons.report, 
                  'Report',
                  onTap: () => _navigateToPage(const ComingSoon()), 
                ),
                _buildMenuItem(
                  Icons.logout, 
                  'Log out',
                  onTap: () => _handleLogout(),
                ),]))
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text,{required VoidCallback onTap}) {
    return Column(
      children: [
      GestureDetector(
         onTap: onTap, 
        child: Icon(icon, size: 35, color: Colors.grey[700])),
       const SizedBox(height: 5),
        Text(text, style: TextStyle(color: Colors.grey[700])),
      ],
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

                                  Navigator.of(context, rootNavigator: true)
                                      .pushAndRemoveUntil(
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

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // --- Blue Path (Bottom Section) ---
    var paintBlue = Paint()..color = Colors.indigo.shade900;
    var pathBlue = Path();

    pathBlue.moveTo(0, size.height * 0.7); 
    pathBlue.quadraticBezierTo(size.width / 2, size.height * 0.85, size.width, size.height * 0);
    pathBlue.lineTo(size.width, size.height);
    pathBlue.lineTo(0, size.height);
    pathBlue.close();
    canvas.drawPath(pathBlue, paintBlue);

    // --- Yellow Path (Top Section) ---
    var paintYellow = Paint()..color =Color(0xFFFFDA45);
    var pathYellow = Path();

    pathYellow.moveTo(0, 0.2);
    pathYellow.lineTo(size.width*1.1, 0);
    pathYellow.quadraticBezierTo(size.width *0.9, size.height * 0.9, 0.1, size.height * 0.9);
    pathYellow.close();
    canvas.drawPath(pathYellow, paintYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}