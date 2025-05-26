import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'profile_edit.dart';

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

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
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
              : SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return RefreshIndicator(
                        onRefresh: _refreshUserData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 80),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: IntrinsicHeight(
                              child: Column(
                                children: [
                                  _buildProfileHeader(),
                                  const SizedBox(height: 20),
                                  _buildActionButtons(),
                                  const Divider(
                                      height: 30, thickness: 1, indent: 20, endIndent: 20),
                                  _buildSection('Saved'),
                                  _buildSection('History'),
                                  _buildSection('My Ratings'),
                                  _buildSection('Help Center'),
                                  _buildSection('Customer Service'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final String userName = _appUser?.name ?? 'Loading User...';
    final String profileUrl = _appUser?.profileImageUrl ??
        'lib/assets/images/placeholder_profile.png';
    final String memberSinceText = _appUser != null
        ? 'Since ${DateFormat('d MMMM y').format(_appUser!.memberSince)}'
        : 'Since N/A';
    final String studentStatus = _appUser?.studentStatus ?? '';
    final String authProvider = _appUser?.authProvider ?? 'email';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 20),
            Stack(
              children: [
                CircleAvatar(
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
                          decoration: const BoxDecoration(
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
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    memberSinceText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  if (studentStatus.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            studentStatus,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 16, color: Colors.blue),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black, size: 28),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
                _fetchUserData(); // Refresh data after returning from edit page
              },
            ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(Icons.wallet, 'ExploraPay'),
          _buildActionButton(Icons.star, 'Points'),
          _buildActionButton(Icons.card_giftcard, 'Voucher'),
          _buildActionButton(Icons.payment, 'PayLater'),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Lorem ipsum dolor sit amet, consectetur adipisci',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}