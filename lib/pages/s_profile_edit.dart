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
  
  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

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
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            _nameController.text = userData['name'] ?? _currentUser!.displayName ?? '';
            _mobileNoController.text = userData['mobileNo'] ?? '';
            _emailController.text = userData['email'] ?? _currentUser!.email ?? '';
            _selectedGender = userData['gender'];
            _profileImageUrl = userData['profileImageUrl'] ?? _currentUser!.photoURL;
            
            if (_currentUser!.metadata.creationTime != null) {
              _memberSinceText = 'Member since ${DateFormat('MMM yyyy').format(_currentUser!.metadata.creationTime!)}';
            } else {
              _memberSinceText = 'Member since Unknown';
            }
          });
        } else {
          String displayName = _currentUser!.displayName ?? 
                              (_currentUser!.email?.split('@')[0] ?? 'User');
          String email = _currentUser!.email ?? '';
          String? photoURL = _currentUser!.photoURL;
          
          await _createUserDocument(displayName, email, photoURL);
          
          setState(() {
            _nameController.text = displayName;
            _emailController.text = email;
            _profileImageUrl = photoURL;
            
            if (_currentUser!.metadata.creationTime != null) {
              _memberSinceText = 'Member since ${DateFormat('MMM yyyy').format(_currentUser!.metadata.creationTime!)}';
            } else {
              _memberSinceText = 'Member since Unknown';
            }
          });
        }
      } else {
        setState(() {
          _errorMessage = "No user logged in";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching user data: $e";
      });
      print("Error fetching user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createUserDocument(String name, String email, String? photoURL) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
        'name': name,
        'email': email,
        'profileImageUrl': photoURL,
        'mobileNo': '',
        'gender': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("User document created for Google Sign-in user");
    } catch (e) {
      print("Error creating user document: $e");
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
      final imageRef = storageRef.child('profile_images/${_currentUser!.uid}.jpg');
      
      await imageRef.putFile(_pickedImage!);
      
      String downloadURL = await imageRef.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception('Failed to upload profile image: $e');
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
          try {
            newProfileImageUrl = await _uploadImage();
          } catch (e) {
            setState(() {
              _isLoading = false;
            });
            _showAlertDialog('Upload Error', e.toString());
            return;
          }
        }

        await _currentUser!.updateDisplayName(_nameController.text.trim());
        if (newProfileImageUrl != null && newProfileImageUrl != _profileImageUrl) {
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
            'gender': _selectedGender,
            'profileImageUrl': newProfileImageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        setState(() {
          _profileImageUrl = newProfileImageUrl;
          _pickedImage = null;
        });

        _showAlertDialog('Success', 'Profile updated successfully!');
      } else {
        _showAlertDialog('Error', 'No user logged in.');
      }
    } on FirebaseAuthException catch (e) {
      _showAlertDialog('Update Error', e.message ?? 'An authentication error occurred.');
    } on FirebaseException catch (e) {
      _showAlertDialog('Database Error', e.message ?? 'A database error occurred.');
    } catch (e) {
      _showAlertDialog('Error', 'An unexpected error occurred: ${e.toString()}');
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

  ImageProvider _getProfileImageProvider() {
    if (_pickedImage != null) {
      return FileImage(_pickedImage!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    } else {
      return const AssetImage('lib/assets/images/placeholder_grey.png');
    }
  }

  bool _shouldShowDefaultIcon() {
    return _profileImageUrl == null && _pickedImage == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
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
                )
              : Stack(
                  children: [
                    // Gradient background
                    Container(
                      width: double.infinity,
                      height: 300,
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
                    
                    // Content
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          // Custom App Bar
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                   // Balance the back button
                                ],
                              ),
                            ),
                          ),
                          
                          // Profile section
                          Container(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 4,
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
                                          radius: 43,
                                          backgroundImage: _getProfileImageProvider(),
                                          onBackgroundImageError: (exception, stackTrace) {
                                            print('Error loading profile image: $exception');
                                          },
                                          child: _shouldShowDefaultIcon() 
                                              ? Container(
                                                  width: 86,
                                                  height: 86,
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.grey,
                                                  ),
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 50,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: _pickImage,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFD700),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.black,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _nameController.text.isNotEmpty ? _nameController.text : 'User',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          _memberSinceText,
                                          style: TextStyle(
                                            fontSize: 14,
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
                          
                          // Form section
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTextField(
                                    controller: _nameController,
                                    labelText: 'Full Name',
                                    hintText: 'Enter your full name',
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
                                    labelText: 'Mobile number',
                                    hintText: 'Enter your Mobile Number',
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                                          return 'Enter a valid mobile number';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _emailController,
                                    labelText: 'Email ID',
                                    hintText: 'Enter your email ID',
                                    keyboardType: TextInputType.emailAddress,
                                    readOnly: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email ID';
                                      }
                                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildGenderDropdown(),
                                  const SizedBox(height: 40),
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _saveUserData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFD700),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2, 
                                                color: Colors.black,
                                              ),
                                            )
                                          : const Text(
                                              'Submit',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 60),
                                ],
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
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(255, 148, 148, 148),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color.fromARGB(255, 105, 104, 104),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            filled: true,
            fillColor: const Color.fromARGB(255, 248, 246, 246),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(255, 148, 148, 148),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          hint: const Text(
            'Select',
            style: TextStyle(
              color: Color.fromARGB(255, 105, 104, 104),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          items: _genderOptions.map((String gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(
                gender,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            filled: true,
            fillColor: const Color.fromARGB(255, 248, 246, 246),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
        ),
      ],
    );
  }
}