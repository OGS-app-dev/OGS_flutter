import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/pages/loginpage.dart';

class Profilepage extends StatelessWidget {
  const Profilepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Logout",
              style: GoogleFonts.outfit(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: pricol,
              ),
            ),
            IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    /*Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const LoginPage())
                            ,(Route<dynamic> route) => false
                        );*/

                    Navigator.of(context, rootNavigator: true)
                        .pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (BuildContext context) {
                          return const LoginPage();
                        },
                      ),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(
                  Icons.logout,
                  size: 30,
                )),
          ],
        ),
      ),
    );
  }
}
