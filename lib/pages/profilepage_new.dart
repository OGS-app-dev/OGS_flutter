import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'profile_edit.dart';

class AppUser {
  final String uid;
  final String name;
  final String profileImageUrl;
  final DateTime memberSince;
  final String studentStatus;

  AppUser({
    required this.uid,
    required this.name,
    required this.profileImageUrl,
    required this.memberSince,
    required this.studentStatus,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? 'User Name',
      profileImageUrl: data['profileImageUrl'] ??
          'lib/assets/images/placeholder_profile.png',
      memberSince:
          (data['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
      studentStatus: data['studentStatus'] ?? '',
    );
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
    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (userDoc.exists) {
          _appUser = AppUser.fromFirestore(userDoc);
        } else {
          _appUser = AppUser(
            uid: _currentUser!.uid,
            name: _currentUser!.displayName ??
                _currentUser!.email?.split('@')[0] ??
                'Guest User',
            profileImageUrl: _currentUser!.photoURL ??
                'lib/assets/images/placeholder_profile.png',
            memberSince: DateTime.now(),
            studentStatus: '',
          );
          _errorMessage =
              "User profile data not found in Firestore. Showing default.";
        }
      } else {
        _errorMessage = "No active user logged in. Please log in.";
      }
    } catch (e) {
      _errorMessage = "Error fetching user data: $e";
      print(_errorMessage);
      if (_currentUser != null && _appUser == null) {
        _appUser = AppUser(
          uid: _currentUser!.uid,
          name: _currentUser!.displayName ??
              _currentUser!.email?.split('@')[0] ??
              'Error User',
          profileImageUrl: _currentUser!.photoURL ??
              'lib/assets/images/placeholder_profile.png',
          memberSince: DateTime.now(),
          studentStatus: '',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _appUser == null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
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
    );
  }

  Widget _buildProfileHeader() {
    final String userName = _appUser?.name ?? 'Loading User...';
    final String profileUrl = _appUser?.profileImageUrl ??
        'lib/assets/images/placeholder_profile.png'; // <--- Ensure this fallback
    final String memberSinceText = _appUser != null
        ? 'Since ${DateFormat('d MMMM y').format(_appUser!.memberSince)}'
        : 'Since N/A';
    final String studentStatus = _appUser?.studentStatus ?? '';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
            ),
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
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
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
        const SizedBox(height: 20),
        // Spacing between sections
      ],
    );
  }
}
