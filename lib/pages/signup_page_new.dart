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
  const SignupPageNew({super.key});

  @override
  State<SignupPageNew> createState() => _SignupPageNewState();
}

enum Gender { male, female, others }

class _SignupPageNewState extends State<SignupPageNew> {
  Gender? _selectedGender = Gender.male;
  bool _obscureText = true; // State to manage password visibility
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passcontroller = TextEditingController();
  TextEditingController namecontroller = TextEditingController();
  TextEditingController dobcontroller = TextEditingController();

  FormResponse? formResponse;

  @override
  void dispose() {
    emailcontroller.dispose();
    passcontroller.dispose();
    namecontroller.dispose();
    dobcontroller.dispose();
    super.dispose();
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
        builder: (context) => const LoginPageNew(),
      ),
    );
  }

  Future<void> signup() async {
    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss by tapping outside
      builder: (context) => const Center(
        child: SpinKitThreeBounce(
          color: Colors.black,
          size: 30,
        ),
      ),
    );

    try {
      // 1. Create user with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailcontroller.text.trim(),
        password: passcontroller.text.trim(),
      );

      // Check if widget is still mounted before proceeding with UI updates/navigation
      if (!mounted) return;

      // 2. Store additional user info in Firestore
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'email': emailcontroller.text.trim(),
          'name': namecontroller.text.trim(),
          'dateOfBirth': dobcontroller.text.trim(),
          'gender': _selectedGender?.name, // Store gender as a string (e.g., 'male', 'female')
          'role': 'student', // Default role for new sign-ups
        });
      }

      // Check if widget is still mounted after Firestore write
      if (!mounted) return;

      // 3. Dismiss loading dialog
      Navigator.pop(context);

      // 4. Navigate to the main page or a success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainPage(), // Assuming MainPage is your main app screen
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Ensure dialog is popped even on FirebaseAuth errors
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
      }

      // Check mounted again before showing alert
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Up Error'),
          content: Text(e.message ?? 'An unknown authentication error occurred.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Ensure dialog is popped on any other unexpected errors
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
      }

      // Check mounted again before showing alert
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('An unexpected error occurred: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
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
          color: pricol, // Assuming 'pricol' is defined in constants.dart
          size: 30,
        ),
      ),
    );
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser == null) {
        if (mounted) {
          Navigator.pop(context); // Dismiss loading dialog if user cancels Google sign-in
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

      if (!mounted) return; // Check mounted before Firestore interaction

      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // Store the user info in Firestore for the first time
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'username': user.displayName,
            'email': user.email,
            'role': "student",
            // Note: DOB and Gender are not collected via Google sign-in directly.
            // You might need a separate onboarding step if they are mandatory.
          });
        }
      }

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        Navigator.pushReplacement( // Use pushReplacement to prevent back button to signup
          context,
          MaterialPageRoute(
            builder: (context) => const MainPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Google Sign-In Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900), // Start from an appropriate past year
      lastDate: DateTime.now(), // End at current date (or a future date if allowed)
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 11, 4, 66), // Header color
              onPrimary: Colors.white, // Text color on header
              surface: Colors.white, // Calendar background
              onSurface: Color.fromARGB(255, 11, 4, 66), // Calendar text color
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: Colors.white, // Dialog background
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 11, 4, 66), // Button text color
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
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                labelText: 'Name',
                labelStyle: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                hintText: 'Enter your Full Name',
                hintStyle: const TextStyle(color: Colors.grey),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                
              ),
              
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              controller: dobcontroller,
              style: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
              readOnly: true, // Makes the field non-editable, relying on the picker
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                labelText: 'Date of Birth',
                labelStyle: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                hintText: 'MM/DD/YYYY',
                hintStyle: const TextStyle(color: Colors.grey),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today, color: Color.fromARGB(197, 11, 4, 66)),
                  onPressed: () => _selectDate(context), // Opens the date picker
                ),
              ),
            ),
            const SizedBox(height: 15.0),
           const Padding(
             padding:  EdgeInsets.only(left: 10),
             child:  Text('Gender',style: TextStyle(color: Color.fromARGB(210, 4, 1, 23)),),
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
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                labelText: 'Email',
                labelStyle: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                hintText: 'Enter your Email Address',
                hintStyle: const TextStyle(color: Colors.grey),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              controller: passcontroller,
              obscureText: _obscureText, // Uses the state variable for visibility
              style: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                labelText: 'Password',
                labelStyle: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.grey),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color.fromARGB(197, 11, 4, 66), width: 2.5),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText; // Toggle password visibility
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.infinity, // Make button take full width
              child: ElevatedButton(
                onPressed: signup, // Calls the signup function
                style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 5), 
                  fixedSize: const Size(350, 50), // You can make this dynamic if needed
                  backgroundColor: const Color.fromARGB(197, 11, 4, 66),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                ),
                child: const Text('Sign Up',style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 20.0),
            const Row(
              children: <Widget>[
                Expanded(child: Divider(color: Colors.black26)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('OR',
                      style: TextStyle(color: Colors.black54, fontSize: 20)),
                ),
                Expanded(child: Divider(color: Colors.black26)),
              ],
            ),
            const Center(
              child: Text('Continue With',
                  style: TextStyle(color: Colors.black54, fontSize: 20)),
            ),
            const SizedBox(height: 25.0),
            Center(
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      signInWithGoogle(); // Calls Google sign-in
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
                      apple(); // Calls Apple sign-in (currently navigates to ComingSoon)
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
                    navigateToLogin(); // Navigates to the login page
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
    );
  }
}