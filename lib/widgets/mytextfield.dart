import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogs/constants.dart';


class MyTextField extends StatelessWidget {
  const MyTextField(
      {super.key,
      this.wid=-99,
      this.colo=pricol,
      this.hintText = '',
      this.obsctext=false,
      required this.title,
      required this.controller});
 
  final String hintText;
  final bool obsctext;
  final String title;
  final TextEditingController controller;
  final double? wid;
  final Color colo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wid==-99?MediaQuery.of(context).size.width * 0.8:wid,
      child: TextField(
        style: TextStyle(color: colo),
        obscureText: obsctext,
        controller: controller,
        cursorColor: seccol,
        decoration: InputDecoration(
          labelText: title,
          labelStyle: GoogleFonts.urbanist(
            textStyle: const TextStyle(
              color: seccol,
              fontSize: 19,
              fontWeight: FontWeight.w600
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: tercol),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: seccol, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          hoverColor: Colors.blueAccent,
        ),
      ),
    );
  }
}
