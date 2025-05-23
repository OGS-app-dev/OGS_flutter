import 'package:flutter/material.dart';
import 'dart:async';

class ConfirmOtpPage extends StatefulWidget {
  final String email;

  const ConfirmOtpPage({super.key, required this.email});

  @override
  State<ConfirmOtpPage> createState() => _ConfirmOtpPageState();
}

class _ConfirmOtpPageState extends State<ConfirmOtpPage> {
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _focusNodes;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final int _otpLength = 6;

  Timer? _resendTimer;
  int _resendTimerSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _otpControllers =
        List.generate(_otpLength, (index) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (index) => FocusNode());

    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimerSeconds = 60; // Reset timer
    _resendTimer?.cancel(); // Cancel any existing timer

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimerSeconds == 0) {
        setState(() {
          _canResend = true;
          timer.cancel(); // Stop the timer
        });
      } else {
        setState(() {
          _resendTimerSeconds--;
        });
      }
    });
  }

  // Function to simulate resending the OTP
  Future<void> _resendOtp() async {
    if (_canResend) {
      setState(() {
        _isLoading = true;
        _canResend = false; // Disable resend button immediately
      });

      // Clear all OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
      // Move focus to the first OTP field
      FocusScope.of(context).requestFocus(_focusNodes[0]);

      // Simulate API call to resend OTP
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New OTP has been sent to your email.'),
          backgroundColor: Colors.green,
        ),
      );
      _startResendTimer(); // Restart the cooldown timer
    }
  }

  // Function to combine OTP digits and verify
  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String enteredOtp =
          _otpControllers.map((controller) => controller.text).join();

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      if (enteredOtp == "123456") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to the ResetPasswordPage, passing the email
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ResetPasswordPage(email: widget.email),
        //   ),
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Confirm OTP',
          style: TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(197, 11, 4, 66)),
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
                'Enter OTP',
                style: TextStyle(
                  fontSize: 24.0,
                  color: Color.fromARGB(197, 11, 4, 66),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                'A 6-digit code has been sent to ${widget.email}. Please enter it below.',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30.0),
              // OTP input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_otpLength, (index) {
                  return SizedBox(
                    width: 50, // Adjust width for each digit field
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1, // Allow only one digit
                      style: const TextStyle(
                          color: Color.fromARGB(197, 11, 4, 66),
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: "", // Hide the character counter
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(
                              color: Color.fromARGB(197, 11, 4, 66),
                              width: 2.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(
                              color: Color.fromARGB(197, 11, 4, 66),
                              width: 2.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(
                              color: Color.fromARGB(197, 11, 4, 66),
                              width: 2.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 2.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 2.5),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length == 1) {
                          if (index < _otpLength - 1) {
                            FocusScope.of(context)
                                .requestFocus(_focusNodes[index + 1]);
                          } else {
                            FocusScope.of(context).unfocus();
                          }
                        } else if (value.isEmpty) {
                          if (index > 0) {
                            FocusScope.of(context)
                                .requestFocus(_focusNodes[index - 1]);
                          }
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return ''; // Return an empty string for a subtle error indicator
                        }
                        return null;
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _canResend
                        ? "Didn't receive code?"
                        : "Resend code in ${_resendTimerSeconds}s",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: _canResend ? _resendOtp : null,
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        color: _canResend
                            ? const Color.fromARGB(197, 11, 4, 66)
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Verify OTP',
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
