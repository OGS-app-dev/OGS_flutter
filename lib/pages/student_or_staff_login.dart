import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/pages/google_sign_in.dart';
import 'package:ogs/pages/loginpage.dart';

class StudentOrStaff extends StatelessWidget {
  const StudentOrStaff({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  LineIcons.mapMarker,
                  size: 350,
                  color: yel,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GoogleSignInPage(),
                        ));
                  },
                  child: Container(
                    height: 60,
                    width: 230,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: pricol,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 30),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 45, vertical: 12),
                    child: Center(
                      child: Text(
                        'Student',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(),
                    Text(
                      "or",
                      style: GoogleFonts.outfit(
                        color: pricol,
                        fontSize: 20,
                      ),
                    ),
                    Container()
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ));
                  },
                  child: Container(
                    height: 60,
                    width: 230,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: pricol,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 30),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 45, vertical: 12),
                    child: Center(
                      child: Text(
                        'Staff',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
