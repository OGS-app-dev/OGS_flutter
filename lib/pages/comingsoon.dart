import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Coming soon....",
          style: GoogleFonts.outfit(fontSize: 30),
        ),
      ),
    );
  }
}
