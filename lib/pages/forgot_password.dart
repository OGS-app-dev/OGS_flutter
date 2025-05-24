import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController emailcontroller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailcontroller.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; 
      });

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: emailcontroller.text.trim(), 
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'a password reset link has been sent to this email'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); 
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message =
              ' a password reset link has been sent to this email';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is not valid.';
        } else {
          message = 'An error occurred. Please try again later.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
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
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: Color.fromARGB(197, 11, 4, 66),fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Remove shadow
        iconTheme: const IconThemeData(color: Color.fromARGB(197, 11, 4, 66)), // Back button color
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey, // Assign the form key
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 15.0),
              const Text(
                'Enter your email address below to receive a password reset link.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: emailcontroller,
                keyboardType: TextInputType.emailAddress, // Set keyboard type for email
                style: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                  hintText: 'Enter your Email',
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
                  errorBorder: OutlineInputBorder( // Style for error state
                    borderSide: const BorderSide(color: Colors.red, width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder( // Style for focused error state
                    borderSide: const BorderSide(color: Colors.red, width: 2.5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address.';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address.';
                  }
                  return null; 
                },
              ),
              const SizedBox(height: 100),
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendPasswordResetEmail, // Call Firebase method
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(350, 50),
                    backgroundColor: const Color.fromARGB(197, 11, 4, 66),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Send Reset Link', 
                          style: TextStyle(fontSize: 20),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
