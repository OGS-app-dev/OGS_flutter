import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/pages/bottomnavpage.dart';
import 'package:ogs/services/points_service.dart';


class GoogleSignInPage extends StatefulWidget {
  const GoogleSignInPage({super.key});

  @override
  State<GoogleSignInPage> createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
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
          await PointsService.initializeUserPoints(user.uid);
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
      body: Center(
        child: GestureDetector(
          onTap: () {
            signInWithGoogle();
          },
          child: Container(
            height: 65,
            width: 250,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              color: const Color.fromARGB(255, 17, 23, 101),
            ),
            child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        height: 30,
                        child: Image.asset('lib/assets/icons/google.png')),
                    const SizedBox(
                      width: 15,
                    ),
                    Text(
                      "Google",
                      style: GoogleFonts.outfit(
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        color: const Color.fromARGB(255, 135, 148, 154)
                      ),
                    )
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
