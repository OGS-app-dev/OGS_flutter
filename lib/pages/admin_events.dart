import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/models/event_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EventAdminDashboard extends StatefulWidget {
  const EventAdminDashboard({super.key});

  @override
  State<EventAdminDashboard> createState() => _EventAdminDashboardState();
}

class _EventAdminDashboardState extends State<EventAdminDashboard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  final _siteUrlController = TextEditingController();
  
  String _selectedCategory = 'event';
  String _selectedCollection = 'events';
  bool _isLive = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _categories = ['event', 'url'];
  final List<String> _collections = ['events', 'urls'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _siteUrlController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
    _dateController.clear();
    _timeController.clear();
    _locationController.clear();
    _siteUrlController.clear();
    setState(() {
      _selectedCategory = 'event';
      _selectedCollection = 'events';
      _isLive = false;
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
          _imageUrlController.clear();
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
      final String fileName = '${_selectedCategory}s/${DateTime.now().millisecondsSinceEpoch}_${_nameController.text.trim().replaceAll(' ', '_').toLowerCase()}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      final TaskSnapshot snapshot = await uploadTask;
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

  Future<void> _selectDate() async {
    if (_selectedCategory == 'url') return; // No date needed for URLs
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _selectTime() async {
    if (_selectedCategory == 'url') return; // No time needed for URLs
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
      String? imageUrl = _uploadedImageUrl;
      if (_selectedImage != null && imageUrl == null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        imageUrl = _imageUrlController.text.trim();
      }

      final event = Event(
        id: '',
        name: _nameController.text.trim(),
        description: _selectedCategory == 'url' ? (_descriptionController.text.trim().isEmpty ? 'Visit this link' : _descriptionController.text.trim()) : _descriptionController.text.trim(),
        imageUrl: imageUrl!,
        date: _selectedCategory == 'url' ? 'N/A' : _dateController.text.trim(),
        time: _selectedCategory == 'url' ? 'N/A' : _timeController.text.trim(),
        location: _locationController.text.trim(),
        isLive: _isLive,
        siteUrl: _siteUrlController.text.trim().isEmpty ? null : _siteUrlController.text.trim(),
        category: _selectedCategory,
      );

      await FirebaseFirestore.instance
          .collection(_selectedCollection)
          .add(event.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedCategory == 'event' ? 'Event' : 'URL'} added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding ${_selectedCategory}: ${e.toString()}'),
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

  void _onCategoryChanged(String? newCategory) {
    if (newCategory != null) {
      setState(() {
        _selectedCategory = newCategory;
        _selectedCollection = newCategory == 'event' ? 'events' : 'urls';
        
        // Clear form when switching categories
        _dateController.clear();
        _timeController.clear();
        _locationController.clear();
        _descriptionController.clear();
        _isLive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Add new Event/Url',
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
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New ${_selectedCategory == 'event' ? 'Event' : 'URL'}',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: pricol,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in the details below to add a new ${_selectedCategory == 'event' ? 'event' : 'URL'} to the database.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Selection
              Text(
                'Select Type *',
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
                  value: _selectedCategory,
                  isExpanded: true,
                  underline: Container(),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: _onCategoryChanged,
                ),
              ),
              const SizedBox(height: 20),

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
                        collection.toUpperCase(),
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

              // Name Field (Mandatory)
              _buildFormField(
                label: '${_selectedCategory == 'event' ? 'Event' : 'URL'} Name *',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '${_selectedCategory == 'event' ? 'Event' : 'URL'} name is required';
                  }
                  return null;
                },
                hintText: 'Enter ${_selectedCategory == 'event' ? 'event' : 'URL'} name',
              ),

              // Description Field (Optional for URLs, Mandatory for Events)
              _buildFormField(
                label: 'Description ${_selectedCategory == 'event' ? '*' : '(Optional)'}',
                controller: _descriptionController,
                validator: _selectedCategory == 'event' ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required for events';
                  }
                  return null;
                } : null,
                hintText: _selectedCategory == 'event' 
                    ? 'Enter event description' 
                    : 'Enter URL description (optional)',
                maxLines: 3,
              ),

              // Image Selection Section
              _buildImageSelectionSection(),

              // Image URL Field (Alternative to image upload)
              _buildFormField(
                label: 'OR Enter Image URL',
                controller: _imageUrlController,
                validator: (value) {
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
                enabled: _selectedImage == null,
              ),

              // Date Field (Only for Events)
              if (_selectedCategory == 'event')
                _buildDateTimeField(
                  label: 'Event Date *',
                  controller: _dateController,
                  hintText: 'Select event date',
                  onTap: _selectDate,
                  icon: Icons.calendar_today,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Event date is required';
                    }
                    return null;
                  },
                ),

              // Time Field (Only for Events)
              if (_selectedCategory == 'event')
                _buildDateTimeField(
                  label: 'Event Time *',
                  controller: _timeController,
                  hintText: 'Select event time',
                  onTap: _selectTime,
                  icon: Icons.access_time,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Event time is required';
                    }
                    return null;
                  },
                ),

              // Location Field (Mandatory - for Events it's venue, for URLs it's the URL)
              _buildFormField(
                label: _selectedCategory == 'event' ? 'Venue *' : 'URL *',
                controller: _locationController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '${_selectedCategory == 'event' ? 'Venue' : 'URL'} is required';
                  }
                  if (_selectedCategory == 'url' && !Uri.tryParse(value.trim())!.hasAbsolutePath) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
                hintText: _selectedCategory == 'event' 
                    ? 'Enter event venue' 
                    : 'Enter the URL',
              ),

              // Site URL Field (Optional - for additional links)
              _buildFormField(
                label: 'Additional URL (Optional)',
                controller: _siteUrlController,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!Uri.tryParse(value.trim())!.hasAbsolutePath) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
                hintText: 'Enter additional URL (optional)',
              ),

              // Live Status Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live Status',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Switch(
                      value: _isLive,
                      onChanged: (bool value) {
                        setState(() {
                          _isLive = value;
                        });
                      },
                      activeColor: Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addItem,
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
                      : Text(
                          'Add ${_selectedCategory == 'event' ? 'Event' : 'URL'}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
                  child: Text(
                    'Clear Form',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.info_circle, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedCategory == 'event' 
                          ? '• All fields marked with * are mandatory for events\n'
                            '• Date and time are required for events\n'
                            '• Venue field is for the event location\n'
                            '• Additional URL is optional for extra links\n'
                            '• You can either upload an image or provide an image URL\n'
                            '• Live status shows a "Live" badge on the event card'
                          : '• Name and URL fields are mandatory for URLs\n'
                            '• Description is optional for URLs\n'
                            '• URL field should contain the actual link\n'
                            '• Additional URL is for extra links if needed\n'
                            '• You can either upload an image or provide an image URL\n'
                            '• Live status shows a "Live" badge on the URL card',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.amber[700],
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
          'Image *',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
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
                                'Uploading...',
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
                      CupertinoIcons.photo,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to select image',
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
                        'Select Image',
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
    int maxLines = 1,
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
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.outfit(
              color: enabled ? Colors.grey[600] : Colors.grey[400],
              fontSize: 14,
            ),
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

  Widget _buildDateTimeField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onTap,
    required IconData icon,
    String? Function(String?)? validator,
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
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.outfit(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            suffixIcon: Icon(icon, color: pricol),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}