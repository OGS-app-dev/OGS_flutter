import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:ogs/pages/bottomnavpage.dart';
import 'comingsoon.dart';
import 'loginpage_new.dart';

class SignupPageNew extends StatefulWidget {
  final String role;
  const SignupPageNew({super.key, required this.role});

  @override
  State<SignupPageNew> createState() => _SignupPageNewState();
}

enum Gender { male, female, others }

class _SignupPageNewState extends State<SignupPageNew> {
  Gender? _selectedGender = Gender.male;
  bool _obscureText = true;
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passcontroller = TextEditingController();
  TextEditingController namecontroller = TextEditingController();
  TextEditingController dobcontroller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  FormResponse? formResponse;

  @override
  void dispose() {
    emailcontroller.dispose();
    passcontroller.dispose();
    namecontroller.dispose();
    dobcontroller.dispose();
    super.dispose();
  }

  // Get user-friendly Firebase Auth error message
  String _getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address. Please try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred during sign up. Please try again.';
    }
  }

  void forgotPassword() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ComingSoon(),
      ),
    );
  }

  void apple() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ComingSoon(),
      ),
    );
  }

  void navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPageNew(role: widget.role),
      ),
    );
  }

  Future<void> signup() async {
    if (_formKey.currentState!.validate()) {
      // Show loading spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: SpinKitThreeBounce(
            color: Colors.black,
            size: 30,
          ),
        ),
      );

      try {
        // Create user with email and password
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailcontroller.text.trim(),
          password: passcontroller.text.trim(),
        );

        if (!mounted) return;

        // Store additional user info in Firestore
        if (userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'uid': userCredential.user!.uid,
            'email': emailcontroller.text.trim(),
            'name': namecontroller.text.trim(),
            'dateOfBirth': dobcontroller.text.trim(),
            'gender': _selectedGender?.name,
            'role': widget.role,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (!mounted) return;

        Navigator.pop(context); // Close loading dialog

        // Navigate to main page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainPage(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
        }

        if (!mounted) return;

        // Show user-friendly error message using SnackBar
        String errorMessage = _getFirebaseAuthErrorMessage(e.code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
        }

        if (!mounted) return;

        // Handle other unexpected errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> signInWithGoogle() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: SpinKitThreeBounce(
          color: pricol,
          size: 30,
        ),
      ),
    );
    
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser == null) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      UserCredential? userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'username': user.displayName,
            'email': user.email,
            'role': "student",
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        
        String errorMessage = 'Failed to sign in with Google. Please try again.';
        if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 11, 4, 66),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color.fromARGB(255, 11, 4, 66),
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 11, 4, 66),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('MM/dd/yyyy').format(pickedDate);
      setState(() {
        dobcontroller.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 25.0),
              const Text(
                'Welcome,',
                style: TextStyle(
                  fontSize: 24.0,
                  color: Color.fromARGB(197, 11, 4, 66),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: namecontroller,
                style: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  labelText: 'Name ',
                  labelStyle:
                      const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                  hintText: 'Enter your Full Name',
                  hintStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: dobcontroller,
                style: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                readOnly: true,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  labelText: 'Date of Birth ',
                  labelStyle:
                      const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                  hintText: 'MM/DD/YYYY',
                  hintStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today,
                        color: Color.fromARGB(197, 11, 4, 66)),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select your date of birth';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15.0),
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  'Gender',
                  style: TextStyle(color: Color.fromARGB(210, 4, 1, 23)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: Gender.values.map((gender) {
                  final isSelected = _selectedGender == gender;
                  final label = gender == Gender.male
                      ? 'Male'
                      : gender == Gender.female
                          ? 'Female'
                          : 'Others';

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 238, 241, 248),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color.fromARGB(255, 11, 4, 66),
                          width: 1.5,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () {
                          setState(() {
                            _selectedGender = gender;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 11, 4, 66),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Radio<Gender>(
                              value: gender,
                              groupValue: _selectedGender,
                              onChanged: (Gender? value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(
                                  horizontal: -4, vertical: -4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: emailcontroller,
                style: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  labelText: 'Email',
                  labelStyle:
                      const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                  hintText: 'Enter your Email Address',
                  hintStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address';
                  }
                  
                  final emailRegExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                  if (!emailRegExp.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: passcontroller,
                obscureText: _obscureText,
                style: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  labelText: 'Password',
                  labelStyle:
                      const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                  hintText: 'Password (minimum 6 characters)',
                  hintStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: signup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    fixedSize: const Size(350, 50),
                    backgroundColor: const Color.fromARGB(197, 11, 4, 66),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                  ),
                  child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20.0),
              const Row(
                children: <Widget>[
                  Expanded(child: Divider(color: Colors.black26)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('OR',
                        style: TextStyle(color: Colors.black54, fontSize: 16)),
                  ),
                  Expanded(child: Divider(color: Colors.black26)),
                ],
              ),
              const Center(
                child: Text('Continue With',
                    style: TextStyle(color: Colors.black54, fontSize: 16)),
              ),
              const SizedBox(height: 25.0),
              Center(
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        signInWithGoogle();
                      },
                      style: OutlinedButton.styleFrom(
                        fixedSize: const Size(250, 50),
                        side: const BorderSide(
                            color: Color.fromARGB(197, 11, 4, 66), width: 1.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      icon: Image.asset('lib/assets/icons/google.png',
                          height: 24.0, width: 24.0),
                      label: const Text('Google',
                          style: TextStyle(
                              color: Color.fromARGB(120, 11, 4, 66),
                              fontSize: 20)),
                    ),
                    const SizedBox(height: 32.0),
                    OutlinedButton.icon(
                      onPressed: () {
                        apple();
                      },
                      style: OutlinedButton.styleFrom(
                        fixedSize: const Size(250, 50),
                        side: const BorderSide(
                            color: Color.fromARGB(197, 11, 4, 66), width: 1.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      icon: const Icon(Icons.apple,
                          color: Color.fromARGB(197, 11, 4, 66), size: 35),
                      label: const Text('Apple',
                          style: TextStyle(
                              color: Color.fromARGB(120, 11, 4, 66),
                              fontSize: 20)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Already have an account? ",
                      style: TextStyle(color: Colors.black54)),
                  GestureDetector(
                    onTap: () {
                      navigateToLogin();
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                          color: Color.fromARGB(197, 11, 4, 66),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}