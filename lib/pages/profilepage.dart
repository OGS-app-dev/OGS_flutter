import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:ogs/pages/student_or_staff_login.dart';
import 'package:provider/provider.dart';

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
                  try {
                    await GoogleSignIn().signOut();
                  } catch (e) {
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(e.toString()),
                        ),
                      );
                    }
                  }
                  if (context.mounted) {
                    /*Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const LoginPage())
                            ,(Route<dynamic> route) => false
                        );*/
                    Provider.of<FormResponse>(context, listen: false)
                        .tabController!
                        .jumpToTab(0);

                    Navigator.of(context, rootNavigator: true)
                        .pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (BuildContext context) {
                          return const StudentOrStaff();
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
