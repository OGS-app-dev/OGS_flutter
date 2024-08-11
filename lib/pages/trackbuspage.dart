import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrackBusPage extends StatelessWidget {
  const TrackBusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text("Track Bus Page", style: GoogleFonts.outfit(fontSize: 30)),
      ),
    );
  }
}
