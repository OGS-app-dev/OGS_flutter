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
class LoginPageNew extends StatefulWidget {
  const LoginPageNew({super.key});

  @override
  State<LoginPageNew> createState() => _LoginPageNewState();
}

class _LoginPageNewState extends State<LoginPageNew> {
  bool _obscureText = true; // State to manage password visibility
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passcontroller = TextEditingController();

  FormResponse? formResponse;
  void forgotPassword(){
    Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ComingSoon() ,
              ));
  }

  void apple(){
    Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ComingSoon() ,
              ));
  }
  void singup(){
    Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ComingSoon() ,
              ));
  }
void login() async {
    showDialog(
        context: context,
        builder: (context) => const SpinKitThreeBounce(
              color: Colors.black,
              size: 30,
            ));
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailcontroller.text,
        password: passcontroller.text,
      );
      if (mounted) {
        Navigator.pop(context);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get()
            .then((value) {
          formResponse?.role = value['role'];
        });
        if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainPage(),
              ));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(e.code),
        ),
      );
    }
  }
   Future<void> signInWithGoogle() async {
    showDialog(
        context: context,
        builder: (context) => const SpinKitThreeBounce(
              color: pricol,
              size: 30,
            ));
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser == null) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      UserCredential? userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // Store the user info in Firestore for the first time
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'username': user.displayName,
            'email': user.email,
            'role': "student"
            // Add more fields if needed
          });
        }
      }
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MainPage(),
            ));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(e.toString()),
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
            TextFormField(controller: emailcontroller,
              obscureText: true,
              style: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
              decoration: InputDecoration(
                labelText:
                    'Email', 
                labelStyle:
                    const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
                hintText:
                    'Enter your Email', 
                hintStyle: const TextStyle(
                    color: Colors.grey), 
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
              ),
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              controller: passcontroller,
              obscureText: _obscureText, // Use the state variable here
              style: const TextStyle(color: Color.fromARGB(197, 11, 4, 66)),
              decoration: InputDecoration(
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
                      _obscureText = !_obscureText; // Toggle the state
                    });
                  },
                ),
              ),),
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: GestureDetector(
                    onTap: forgotPassword,
                    child: const Text(
                      'forgot password',
                      style: TextStyle(
                          color: Color.fromARGB(197, 11, 4, 66),
                          fontWeight: FontWeight.bold,fontSize: 14),
                    ),
                  ),
            ),
                const SizedBox(height: 60.0),
            SizedBox(
              // Adjust width as needed
              child: ElevatedButton(
                onPressed:login,
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(350, 50),
                  backgroundColor: const Color.fromARGB(197, 11, 4, 66),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                ),
                child: const Text('Login'),
              ),
            ),
            const SizedBox(height: 60.0),
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
                      // TODO: Implement Google login
                     signInWithGoogle();
                    },
                    style: OutlinedButton.styleFrom(
                      fixedSize: const Size(250, 50),
                      side: const BorderSide(
                          color: Color.fromARGB(197, 11, 4, 66),width: 1.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    icon: Image.asset('lib/assets/icons/google.png',
                        height: 24.0,
                        width:
                            24.0), // Replace with actual Google logo if available as asset
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
                          color: Color.fromARGB(197, 11, 4, 66),width: 1.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    icon: const Icon(Icons.apple,
                        color: Color.fromARGB(197, 11, 4,
                            66),size:35 ,), // Replace with actual Apple logo if available as asset
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
    );
  }
}
