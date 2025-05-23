import 'package:flutter/material.dart';
import 'package:ogs/pages/comingsoon.dart'; // Assuming this path is correct

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  // Controller for the email input field
  TextEditingController emailcontroller = TextEditingController();
  // Global key to manage the form state for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Boolean to control the loading indicator visibility
  bool _isLoading = false;

  @override
  void dispose() {
    // Dispose the controller when the widget is removed from the widget tree
    emailcontroller.dispose();
    super.dispose();
  }

  // Function to simulate sending an OTP and navigate to the OTP page
  Future<void> _sendOtp() async {
    // Validate the form before proceeding
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      // Simulate an API call delay for sending OTP
      // In a real application, you would make an HTTP request to your backend here
      // e.g., using 'http' or 'dio' package.
      // The backend would then send an actual OTP to the provided email.
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      setState(() {
        _isLoading = false; // Hide loading indicator
      });

      // Show a success message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('If an account exists, an OTP has been sent to your email.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the ComingSoon page (which will eventually be the OTP verification page)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ComingSoon(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Optional: Add an app bar for better navigation/context
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
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
              const SizedBox(height: 25.0),
              const Text(
                'Reset Your Password', // More descriptive title
                style: TextStyle(
                  fontSize: 24.0,
                  color: Color.fromARGB(197, 11, 4, 66),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Enter your email address below to receive a One-Time Password (OTP) for password reset.',
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
                  // Basic email format validation
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address.';
                  }
                  return null; // Return null if the input is valid
                },
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity, // Make the button take full width
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp, // Disable button when loading
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
                          'Send OTP',
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