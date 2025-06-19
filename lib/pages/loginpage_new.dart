import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:ogs/pages/bottomnavpage.dart';
import 'package:ogs/pages/signup_page.dart';
import 'package:ogs/widgets/mytextfield.dart';
import 'package:provider/provider.dart';
import 'comingsoon.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogs/pages/signup_page_new.dart';
import 'package:ogs/pages/forgot_password.dart';
import 'package:ogs/services/points_service.dart';

class LoginPageNew extends StatefulWidget {
  final String role;
  const LoginPageNew({super.key, required this.role});

  @override
  State<LoginPageNew> createState() => _LoginPageNewState();
}

class _LoginPageNewState extends State<LoginPageNew> {
  bool _obscureText = true;
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passcontroller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  FormResponse? formResponse;

  @override
  void dispose() {
    emailcontroller.dispose();
    passcontroller.dispose();
    super.dispose();
  }

  // Get user-friendly Firebase Auth error message
  String _getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or sign up for a new account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or use "Forgot Password" to reset it.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email but different sign-in method.';
      default:
        return 'Login failed. Please check your credentials and try again.';
    }
  }

  void forgotPassword() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPassword(),
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

  void singup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignupPageNew(role: widget.role),
      ),
    );
  }

  void login() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if validation fails
    }

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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailcontroller.text.trim(),
        password: passcontroller.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      // Get user role from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get()
          .then((value) {
        if (value.exists) {
          formResponse?.role = value['role'];
        }
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainPage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (!mounted) return;

      // Show user-friendly error message in SnackBar
      String errorMessage = _getFirebaseAuthErrorMessage(e.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
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
          content: Text('Something went wrong. Please check your internet connection and try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
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
      await PointsService.initializeUserPoints(user!.uid);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        
        String errorMessage = 'Failed to sign in with Google. Please try again.';
        if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('cancelled')) {
          return; // Don't show error if user cancelled
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
                controller: emailcontroller,
                style: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  labelText: 'Email ',
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
                  hintText: 'Enter your Password',
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
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: GestureDetector(
                  onTap: forgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                        color: Color.fromARGB(197, 11, 4, 66),
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 60.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    fixedSize: const Size(350, 50),
                    backgroundColor: const Color.fromARGB(197, 11, 4, 66),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                  ),
                  child: const Text('Login', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 60.0),
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
                  const Text("Don't have an account? ",
                      style: TextStyle(color: Colors.black54)),
                  GestureDetector(
                    onTap: () {
                      singup();
                    },
                    child: const Text(
                      'Signup',
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