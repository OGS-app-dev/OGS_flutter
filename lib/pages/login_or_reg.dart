// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:ogs/constants.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: pricol
              ),
              child:const Text("REGISTER"),
            ),
            const SizedBox(height: 30,),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: pricol
              ),
              child: Text("LOGIN"),
            ),

          ],
        )
      ),
    );
  }
}
