import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/models/movies_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MovieAdminDashboard extends StatefulWidget {
  const MovieAdminDashboard({super.key});

  @override
  State<MovieAdminDashboard> createState() => _MovieAdminDashboardState();
}

class _MovieAdminDashboardState extends State<MovieAdminDashboard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _ratingController = TextEditingController();
  final _siteUrlController = TextEditingController();
  
  String _selectedCollection = 'movies_now';
  bool _isLoading = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _collections = [
    'movies_now',
    'movies_upcom',
  ];

  final Map<String, String> _collectionDisplayNames = {
    'movies_now': 'Now Showing',
    'movies_upcom': 'Upcoming Movies',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _ratingController.dispose();
    _siteUrlController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _imageUrlController.clear();
    _ratingController.clear();
    _siteUrlController.clear();
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrlController.clear(); // Clear manual URL if image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    
    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Create a unique filename
      final String fileName = 'movies/${DateTime.now().millisecondsSinceEpoch}_${_nameController.text.trim().replaceAll(' ', '_').toLowerCase()}.jpg';
      
      // Upload to Firebase Storage
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _uploadedImageUrl = downloadUrl;
      });
      
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _addMovie() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if either image is selected or URL is provided
    if (_selectedImage == null && _imageUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please either select an image or provide an image URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image if one is selected
      String? imageUrl = _uploadedImageUrl;
      if (_selectedImage != null && imageUrl == null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        imageUrl = _imageUrlController.text.trim();
      }

      // Parse rating if provided
      double? rating;
      if (_ratingController.text.isNotEmpty) {
        rating = double.tryParse(_ratingController.text);
        if (rating == null || rating < 0 || rating > 10) {
          throw Exception('Rating must be a valid number between 0 and 10');
        }
      }

      // Create movie object
      final movie = Movie(
        id: '', // Will be generated by Firestore
        name: _nameController.text.trim(),
        imageUrl: imageUrl!,
        rating: rating,
        siteUrl: _siteUrlController.text.trim().isEmpty ? null : _siteUrlController.text.trim(),
      );

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection(_selectedCollection)
          .add(movie.toFirestore());

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Movie added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _clearForm();
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding movie: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Add Movie',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: pricol,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.film,
                          color: pricol,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add New Movie',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: pricol,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in the details below to add a new movie to the database.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Collection Selection
              Text(
                'Select Collection *',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedCollection,
                  isExpanded: true,
                  underline: Container(),
                  items: _collections.map((String collection) {
                    return DropdownMenuItem<String>(
                      value: collection,
                      child: Text(
                        _collectionDisplayNames[collection] ?? collection,
                        style: GoogleFonts.outfit(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCollection = newValue;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Movie Name Field (Mandatory)
              _buildFormField(
                label: 'Movie Name *',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Movie name is required';
                  }
                  return null;
                },
                hintText: 'Enter movie name',
                prefixIcon: CupertinoIcons.film,
              ),

              // Image Selection Section
              _buildImageSelectionSection(),

              // Image URL Field (Alternative to image upload)
              _buildFormField(
                label: 'OR Enter Image URL',
                controller: _imageUrlController,
                validator: (value) {
                  // Only validate if no image is selected and URL is provided
                  if (_selectedImage == null && (value == null || value.trim().isEmpty)) {
                    return 'Please either select an image or provide an image URL';
                  }
                  if (value != null && value.trim().isNotEmpty) {
                    if (!Uri.tryParse(value.trim())!.hasAbsolutePath) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
                hintText: 'Enter image URL (if not uploading image)',
                enabled: _selectedImage == null, // Disable if image is selected
                prefixIcon: CupertinoIcons.link,
              ),

              // Rating Field (Optional)
              _buildFormField(
                label: 'Rating (Optional)',
                controller: _ratingController,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final rating = double.tryParse(value.trim());
                    if (rating == null) {
                      return 'Please enter a valid number';
                    }
                    if (rating < 0 || rating > 10) {
                      return 'Rating must be between 0 and 10';
                    }
                  }
                  return null;
                },
                hintText: 'Enter rating (0-10)',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                prefixIcon: CupertinoIcons.star,
              ),

              // Site URL Field (Optional)
              _buildFormField(
                label: 'Movie Website/Booking URL (Optional)',
                controller: _siteUrlController,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!Uri.tryParse(value.trim())!.hasAbsolutePath) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
                hintText: 'Enter website or booking URL',
                prefixIcon: CupertinoIcons.globe,
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addMovie,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pricol,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SpinKitThreeBounce(
                          size: 20,
                          color: Colors.white,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.add_circled, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Add Movie',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Clear Form Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _clearForm,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: pricol,
                    side: BorderSide(color: pricol),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.clear, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Clear Form',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.info_circle, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Fields marked with * are mandatory\n'
                      '• Movie name should be accurate and complete\n'
                      '• Rating should be between 0 and 10 (use decimal if needed)\n'
                      '• You can either upload an image or provide an image URL\n'
                      '• Uploaded images are stored in Firebase Storage\n'
                      '• Website/Booking URL will be opened when users tap the movie\n'
                      '• "Now Showing" for currently playing movies\n'
                      '• "Upcoming Movies" for movies releasing soon\n'
                      '• Make sure all information is accurate before submitting',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Movie Poster *',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
        // Image preview or upload button
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: _selectedImage != null
              ? Stack(
                  children: [
                    // Image preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Remove button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                            _uploadedImageUrl = null;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Upload status
                    if (_isUploadingImage)
                      Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SpinKitThreeBounce(
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Uploading poster...',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.film,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to select movie poster',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(CupertinoIcons.photo_camera, size: 18),
                      label: Text(
                        'Select Poster',
                        style: GoogleFonts.outfit(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pricol,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.outfit(
              color: enabled ? Colors.grey[600] : Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: prefixIcon != null 
                ? Icon(prefixIcon, color: enabled ? pricol : Colors.grey[400], size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: pricol, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: enabled ? Colors.black87 : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}