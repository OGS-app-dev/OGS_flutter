import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'student_or_staff_login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  User? _currentUser;
  String? _profileImageUrl;
  bool _isLoading = true;
  String? _errorMessage;
  File? _pickedImage;
  String? _userName;

  String _memberSinceText = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileNoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        _emailController.text = _currentUser!.email ?? '';

        if (_currentUser!.metadata.creationTime != null) {
          final DateTime creationDateTime =
              _currentUser!.metadata.creationTime!;
          _memberSinceText =
              ' Since ${DateFormat('MMMM d, y').format(creationDateTime)}';
        } else {
          _memberSinceText = 'Member Since: N/A';
        }

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          _nameController.text = data['name'] ?? '';
          _userName = data['name'] ?? 'User';
          _mobileNoController.text = data['mobileNo'] ?? '';
          _profileImageUrl = data['profileImageUrl'];
        } else {
          _nameController.text = _currentUser!.displayName ?? '';
          _errorMessage =
              "User profile data not found in Firestore. Using defaults.";
        }
      } else {
        _errorMessage = "No active user logged in. Please log in.";
      }
    } catch (e) {
      _errorMessage = "Error fetching user data: $e";
      print(_errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null || _currentUser == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef =
          storageRef.child('profile_images/${_currentUser!.uid}.jpg');
      await imageRef.putFile(_pickedImage!);
      return await imageRef.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      _showAlertDialog('Upload Error', 'Failed to upload profile image: $e');
      return null;
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentUser != null) {
        String? newProfileImageUrl = _profileImageUrl;
        if (_pickedImage != null) {
          newProfileImageUrl = await _uploadImage();
        }

        await _currentUser!.updateDisplayName(_nameController.text.trim());
        if (newProfileImageUrl != null) {
          await _currentUser!.updatePhotoURL(newProfileImageUrl);
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .set(
          {
            'name': _nameController.text.trim(),
            'mobileNo': _mobileNoController.text.trim(),
            'email': _emailController.text.trim(),
            'profileImageUrl': newProfileImageUrl,
          },
          SetOptions(merge: true),
        );

        _showAlertDialog('Success', 'Profile updated successfully!');
      } else {
        _showAlertDialog('Error', 'No user logged in.');
      }
    } on FirebaseAuthException catch (e) {
      _showAlertDialog(
          'Update Error', e.message ?? 'An authentication error occurred.');
    } catch (e) {
      _showAlertDialog('Error', 'An unexpected error occurred: $e');
      print("Error saving user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveUserData,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.blue),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 25,
                              ),
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 45,
                                    backgroundImage: _pickedImage != null
                                        ? FileImage(_pickedImage!)
                                            as ImageProvider
                                        : (_profileImageUrl != null &&
                                                    _profileImageUrl!.isNotEmpty
                                                ? NetworkImage(_profileImageUrl!)
                                                : const AssetImage(
                                                    'lib/assets/images/placeholder_grey.png'))
                                            as ImageProvider,
                                    onBackgroundImageError:
                                        (exception, stackTrace) {
                                      print(
                                          'Error loading profile image: $exception');
                                    },
                                    child: _profileImageUrl == null &&
                                            _pickedImage == null
                                        ? Container(
                                            width: 90,
                                            height: 90,
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
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 100, 10, 10),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.edit,
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                            size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text
                                          : 'User',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _memberSinceText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildTextField(
                          controller: _nameController,
                          labelText: 'Name',
                          hintText: 'ENTER YOUR NAME',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _mobileNoController,
                          labelText: 'Mobile No',
                          hintText: 'ENTER YOUR MOBILE NUMBER',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                              return 'Enter a valid mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          labelText: 'Email ID',
                          hintText: 'ENTER YOUR EMAIL ID',
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email ID';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const SizedBox(
                              width: 15,
                            ),
                            Text(
                              "Logout",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: pricol,
                              ),
                            ),
                            IconButton(
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
                                    /*Navigator.of(context).pushAndRemoveUntil(
                                                MaterialPageRoute(
                        builder: (context) => const LoginPage())
                        ,(Route<dynamic> route) => false
                                                );*/
                                    Provider.of<FormResponse>(context,
                                            listen: false)
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
                                icon: const Icon(
                                  Icons.logout,
                                  size: 20,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(
            labelText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87, // Label text color
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: const TextStyle(color: Colors.black), // Color of typed text
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
                color: Color.fromARGB(255, 134, 133, 133)), // Hint text color
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                  color: Color.fromARGB(255, 177, 177, 177)), // Default border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                  color: Colors.blue, width: 2), // Focused border
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                  color: Color.fromARGB(255, 255, 255, 255),
                  width: 0), // Enabled border (invisible in this case)
            ),
            filled: true,
            fillColor: const Color.fromARGB(
                255, 255, 255, 255), // Background fill color
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
