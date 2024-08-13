import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ogs/pages/bottomnavpage.dart';
import 'package:ogs/pages/intropages.dart';



class Landing extends StatelessWidget {
  const Landing({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if(snapshot.hasData){
            return const MainPage();
          }
          else {
            return const IntroPages();
          }
          
        },
      ),
    );
  }
}